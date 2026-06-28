class WeeklyBoxesController < ApplicationController
  before_action :set_weekly_box, only: [:show, :update, :destroy, :add_item, :remove_item, :update_item, :items, :lock]

  def index
    scope = WeeklyBox.includes(weekly_box_items: :vegetable).order(week_start_date: :desc)
    success(scope.as_json(include: { weekly_box_items: { include: :vegetable } }), message: "获取成功")
  end

  def upcoming
    scope = WeeklyBox.upcoming.includes(weekly_box_items: :vegetable).limit(4)
    success(scope.as_json(include: { weekly_box_items: { include: :vegetable } }), message: "获取成功")
  end

  def current
    week_key = params[:week_key] || WeekUtils.current_week_key
    box = WeeklyBox.includes(weekly_box_items: :vegetable).find_by!(week_key: week_key)
    success(box.as_json(include: { weekly_box_items: { include: :vegetable } }), message: "获取成功")
  end

  def show
    success(@weekly_box.as_json(include: { weekly_box_items: { include: :vegetable } }), message: "获取成功")
  end

  def create
    admin_required!
    weekly_box = WeeklyBox.new(weekly_box_params)
    week_key = weekly_box.week_key || WeekUtils.generate_week_key_for_date(weekly_box.week_start_date || Date.today)
    weekly_box.week_key = week_key
    weekly_box.week_start_date ||= WeekUtils.week_start(week_key)
    weekly_box.week_end_date ||= WeekUtils.week_end(week_key)
    weekly_box.lock_at ||= WeekUtils.lock_time_for_week(week_key)

    if weekly_box.save
      success(weekly_box, message: "创建成功")
    else
      error(message: weekly_box.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def update
    admin_required!
    if @weekly_box.is_locked?
      return error(message: "该周盲盒已锁定，无法修改", code: 400, status: :bad_request)
    end
    if @weekly_box.update(weekly_box_params)
      success(@weekly_box, message: "更新成功")
    else
      error(message: @weekly_box.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def destroy
    admin_required!
    if @weekly_box.is_locked? || @weekly_box.orders.exists?
      return error(message: "该周盲盒已有订单或已锁定，无法删除", code: 400, status: :bad_request)
    end
    @weekly_box.destroy
    success(nil, message: "删除成功")
  end

  def items
    success(@weekly_box.weekly_box_items.includes(:vegetable).as_json(include: :vegetable), message: "获取成功")
  end

  def add_item
    admin_required!
    if @weekly_box.is_locked?
      return error(message: "该周盲盒已锁定，无法修改", code: 400, status: :bad_request)
    end
    item = @weekly_box.weekly_box_items.find_or_initialize_by(vegetable_id: params[:vegetable_id])
    item.quantity = params[:quantity].to_i
    if item.save
      success(item.as_json(include: :vegetable), message: "添加成功")
    else
      error(message: item.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def update_item
    admin_required!
    if @weekly_box.is_locked?
      return error(message: "该周盲盒已锁定，无法修改", code: 400, status: :bad_request)
    end
    item = @weekly_box.weekly_box_items.find(params[:item_id])
    if item.update(quantity: params[:quantity].to_i)
      success(item.as_json(include: :vegetable), message: "更新成功")
    else
      error(message: item.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def remove_item
    admin_required!
    if @weekly_box.is_locked?
      return error(message: "该周盲盒已锁定，无法修改", code: 400, status: :bad_request)
    end
    item = @weekly_box.weekly_box_items.find(params[:item_id])
    item.destroy
    success(nil, message: "移除成功")
  end

  def lock
    admin_required!
    WeeklyBoxLockService.lock_week(@weekly_box.week_key)
    success(@weekly_box.reload, message: "锁定成功，订单已生成")
  end

  def check_lock
    admin_required!
    WeeklyBoxLockService.check_and_lock_expired
    success(nil, message: "锁定检查完成")
  end

  private

  def set_weekly_box
    @weekly_box = WeeklyBox.find(params[:id])
  end

  def weekly_box_params
    params.require(:weekly_box).permit(:week_key, :week_start_date, :week_end_date, :lock_at, :price, :stock, :name, :description, :cover_image)
  end
end
