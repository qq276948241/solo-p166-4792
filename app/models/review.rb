class Review < ApplicationRecord
  belongs_to :order
  belongs_to :order_item
  belongs_to :vegetable
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5, message: "评分必须在1到5星之间" }
  validates :order_item_id, uniqueness: { scope: :user_id, message: "该菜品您已经评价过了" }
  validate :order_must_be_signed

  before_save :truncate_comment

  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :low_rating, -> { where(rating: 1..3) }
  scope :high_rating, -> { where(rating: 4..5) }

  private

  def order_must_be_signed
    unless order&.signed?
      errors.add(:base, "订单签收后才能评价")
    end
  end

  def truncate_comment
    self.comment = comment&.truncate(200)
  end
end
