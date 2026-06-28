class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :vegetable
  has_many :reviews, dependent: :nullify

  def review_by(user)
    reviews.find_by(user: user)
  end
end
