class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :sign, :cancel, :items, :swap_vegetable, :update_tracking]

  def index
    scope = current_user.orders.includes(:weekly_box, :subscription).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.by_week(params[:week_key]) if params[:week_key].present?

    success(paginate(scope, page: params[:page], per_page: params[:per_page]), message: "获取成功")
  end

  def show
    success(@order.as_json(include: [:weekly_box, :subscription, { order_items: { include: :vegetable } } ]).merge(address: @order.address_info), message: "获取成功")
  end

  def items
    success(@order.order_items.includes(:vegetable).as_json(include: :vegetable), message: "获取成功")
  end

  def sign
    @order.sign!(remark: params[:remark])
    success(@order, message: "签收成功")
  end

  def cancel
    @order.cancel!(refund: ActiveModel::Type::Boolean.new.cast(params[:refund]))
    success(nil, message: "订单已取消")
  end

  def update_tracking
    admin_required!
    if @order.update(tracking_number: params[:tracking_number], status: :delivering)
      success(@order, message: "发货成功")
    else
      error(message: @order.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def swap_vegetable
    if @order.signed? || @order.cancelled?
      return error(message: "订单状态不允许换菜", code: 400, status: :bad_request)
    end

    if @order.weekly_box.is_locked?
      return error(message: "该周盲盒已锁定，无法换菜", code: 400, status: :bad_request)
    end

    old_item = @order.order_items.find(params[:old_item_id])
    new_vegetable = Vegetable.find(params[:new_vegetable_id])
    new_quantity = (params[:quantity] || old_item.quantity).to_i

    if new_quantity <= 0
      return error(message: "数量必须大于0", code: 400, status: :bad_request)
    end

    ActiveRecord::Base.transaction do
      price_diff = (new_vegetable.price * new_quantity) - (old_item.unit_price * old_item.quantity)
      if price_diff > 0
        current_user.wallet.consume!(price_diff, source: "换菜补差价", order: @order, remark: "订单##{@order.id}换菜")
      elsif price_diff < 0
        current_user.wallet.refund!(price_diff.abs, source: "换菜退差价", order: @order, remark: "订单##{@order.id}换菜")
      end

      old_item.destroy!
      new_item = @order.order_items.create!(
        vegetable: new_vegetable,
        vegetable_name_snapshot: new_vegetable.name,
        vegetable_unit_snapshot: new_vegetable.unit,
        quantity: new_quantity,
        unit_price: new_vegetable.price
      )

      new_total = @order.items_total
      @order.update!(total_amount: new_total)

      success({ new_item: new_item.as_json(include: :vegetable), price_diff: price_diff }, message: "换菜成功")
    end
  end

  def admin_index
    admin_required!
    scope = Order.includes(:user, :weekly_box, :subscription).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.by_week(params[:week_key]) if params[:week_key].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?

    success(paginate(scope, page: params[:page], per_page: params[:per_page]), message: "获取成功")
  end

  private

  def set_order
    @order = if current_user&.admin?
      Order.find(params[:id])
    else
      current_user.orders.find(params[:id])
    end
  end
end
