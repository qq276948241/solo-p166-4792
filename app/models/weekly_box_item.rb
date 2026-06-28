class WeeklyBoxItem < ApplicationRecord
  belongs_to :weekly_box
  belongs_to :vegetable

  validates :quantity, numericality: { greater_than: 0 }
end
