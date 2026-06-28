class WalletsController < ApplicationController
  def show
    success(current_user.wallet.as_json.merge(
      recharge_total: current_user.wallet_transactions.recharge.sum(:amount),
      consume_total: current_user.wallet_transactions.consume.sum(:amount)
    ), message: "获取成功")
  end

  def recharge
    amount = params[:amount].to_d
    source = params[:source] || "线上充值"
    remark = params[:remark]

    if amount <= 0
      return error(message: "充值金额必须大于0", code: 400, status: :bad_request)
    end

    current_user.wallet.recharge!(amount, source: source, remark: remark)
    success(current_user.wallet, message: "充值成功")
  end

  def transactions
    scope = current_user.wallet_transactions.recent
    scope = scope.where(txn_type: params[:txn_type]) if params[:txn_type].present?
    scope = scope.where("created_at >= ?", params[:start_date]) if params[:start_date].present?
    scope = scope.where("created_at <= ?", params[:end_date]) if params[:end_date].present?

    success(paginate(scope, page: params[:page], per_page: params[:per_page]), message: "获取成功")
  end
end
