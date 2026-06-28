class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :update, :destroy, :pause, :resume, :cancel, :skip_week, :unskip_week, :skip_weeks_list]

  def index
    subscriptions = current_user.subscriptions.includes(:address).order(created_at: :desc)
    success(subscriptions.as_json(include: :address), message: "获取成功")
  end

  def show
    success(@subscription.as_json(include: [:address, :skip_weeks]), message: "获取成功")
  end

  def create
    subscription = current_user.subscriptions.build(subscription_params)
    subscription.start_date ||= Date.today

    if subscription.save
      success(subscription, message: "订阅成功")
    else
      error(message: subscription.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def update
    if @subscription.update(subscription_params)
      success(@subscription, message: "更新成功")
    else
      error(message: @subscription.errors.full_messages.join(", "), code: 422, status: :unprocessable_entity)
    end
  end

  def destroy
    @subscription.cancel!
    success(nil, message: "已取消订阅")
  end

  def pause
    @subscription.paused!
    success(@subscription, message: "已暂停订阅")
  end

  def resume
    @subscription.active!
    success(@subscription, message: "已恢复订阅")
  end

  def cancel
    @subscription.cancelled!
    success(@subscription, message: "已取消订阅")
  end

  def skip_week
    week_key = params[:week_key] || WeekUtils.next_week_key
    @subscription.skip_week!(week_key, reason: params[:reason])
    success({ week_key: week_key }, message: "已跳过该周配送")
  end

  def unskip_week
    week_key = params[:week_key]
    @subscription.unskip_week!(week_key)
    success({ week_key: week_key }, message: "已取消跳过")
  end

  def skip_weeks_list
    success(@subscription.skip_weeks.order(week_key: :desc), message: "获取成功")
  end

  private

  def set_subscription
    @subscription = current_user.subscriptions.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:address_id, :frequency, :box_size, :start_date)
  end
end
