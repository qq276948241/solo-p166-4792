class WeeklyBox < ApplicationRecord
  has_many :weekly_box_items, dependent: :destroy
  has_many :vegetables, through: :weekly_box_items
  has_many :orders, dependent: :destroy

  validates :week_key, uniqueness: true, presence: true
  validates :week_start_date, :week_end_date, :lock_at, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :sold_count, numericality: { greater_than_or_equal_to: 0 }

  scope :upcoming, -> { where("week_start_date >= ?", Date.today).order(:week_start_date) }
  scope :unlocked, -> { where(is_locked: false) }

  def lock!
    return if is_locked?
    update!(is_locked: true)
  end

  def can_modify?
    !is_locked? && Time.current < lock_at
  end

  def items_count
    weekly_box_items.sum(:quantity)
  end

  def total_value
    weekly_box_items.includes(:vegetable).sum { |item| item.vegetable.price * item.quantity }
  end

  def remaining_stock
    stock - sold_count
  end
end
