class Vegetable < ApplicationRecord
  has_many :weekly_box_items, dependent: :destroy
  has_many :weekly_boxes, through: :weekly_box_items
  has_many :order_items, dependent: :destroy

  validates :name, :unit, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
end
