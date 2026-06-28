class Wallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy

  def recharge!(amount, source: "系统充值", remark: nil)
    raise "充值金额必须大于0" unless amount.to_d > 0

    ActiveRecord::Base.transaction do
      update!(balance: balance + amount.to_d)
      wallet_transactions.create!(
        user: user,
        amount: amount.to_d,
        balance_after: balance,
        txn_type: :recharge,
        source: source,
        remark: remark
      )
    end
    true
  end

  def consume!(amount, source: "消费", order: nil, remark: nil)
    raise "消费金额必须大于0" unless amount.to_d > 0
    raise "余额不足" if balance < amount.to_d

    ActiveRecord::Base.transaction do
      update!(balance: balance - amount.to_d)
      wallet_transactions.create!(
        user: user,
        amount: amount.to_d,
        balance_after: balance,
        txn_type: :consume,
        source: source,
        order: order,
        remark: remark
      )
    end
    true
  end

  def refund!(amount, source: "退款", order: nil, remark: nil)
    raise "退款金额必须大于0" unless amount.to_d > 0

    ActiveRecord::Base.transaction do
      update!(balance: balance + amount.to_d)
      wallet_transactions.create!(
        user: user,
        amount: amount.to_d,
        balance_after: balance,
        txn_type: :refund,
        source: source,
        order: order,
        remark: remark
      )
    end
    true
  end
end
