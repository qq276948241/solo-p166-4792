class AdminController < ApplicationController
  before_action :admin_required!

  def dashboard
    week_key = params[:week_key] || WeekUtils.current_week_key
    box = WeeklyBox.find_by(week_key: week_key)

    stats = {
      total_users: User.count,
      active_subscriptions: Subscription.active.count,
      week_key: week_key,
      weekly_box: box&.as_json(include: { weekly_box_items: { include: :vegetable } }),
      orders: box ? {
        total: box.orders.count,
        locked: box.orders.locked.count,
        delivering: box.orders.delivering.count,
        signed: box.orders.signed.count,
        cancelled: box.orders.cancelled.count
      } : {}
    }

    success(stats, message: "获取成功")
  end

  def users
    scope = User.order(created_at: :desc)
    scope = scope.where(role: params[:role]) if params[:role].present?
    success(paginate(scope, page: params[:page], per_page: params[:per_page]), message: "获取成功")
  end

  def manual_recharge
    user = User.find(params[:user_id])
    amount = params[:amount].to_d

    if amount <= 0
      return error(message: "充值金额必须大于0", code: 400, status: :bad_request)
    end

    user.wallet.recharge!(amount, source: "管理员充值", remark: params[:remark])
    success(user.wallet, message: "充值成功")
  end
end
