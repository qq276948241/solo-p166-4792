class Order < ApplicationRecord
  belongs_to :subscription
  belongs_to :user
  belongs_to :weekly_box
  has_many :order_items, dependent: :destroy

  enum :status, { locked: 0, delivering: 1, signed: 2, cancelled: 3 }

  validates :week_key, :total_amount, :status, presence: true

  scope :by_week, ->(week_key) { where(week_key: week_key) }
  scope :recent, -> { order(created_at: :desc) }

  def sign!(remark: nil)
    raise "订单状态不允许签收" unless delivering? || locked?

    update!(status: :signed, signed_at: Time.current, sign_remark: remark)
  end

  def cancel!(refund: true)
    raise "已签收订单不能取消" if signed?

    ActiveRecord::Base.transaction do
      if refund && locked?
        user.wallet.refund!(total_amount, source: "订单取消退款", order: self, remark: "订单##{id}取消")
      end
      weekly_box.decrement!(:sold_count) if weekly_box.sold_count > 0
      update!(status: :cancelled)
    end
    true
  end

  def address_info
    JSON.parse(address_snapshot).with_indifferent_access rescue {}
  end

  def items_total
    order_items.sum { |item| item.unit_price * item.quantity }
  end
end
