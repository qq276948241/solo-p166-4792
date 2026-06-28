class User < ApplicationRecord
  has_secure_password

  enum :role, { user: 0, admin: 1 }

  has_one :wallet, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :wallet_transactions, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :phone, presence: true, uniqueness: true,
    format: { with: /\A1[3-9]\d{9}\z/, message: "手机号格式不正确" }
  validates :password, length: { minimum: 6, allow_nil: true }

  after_create :create_default_wallet

  def default_address
    addresses.find_by(is_default: true) || addresses.first
  end

  private

  def create_default_wallet
    create_wallet!(balance: 0)
  end
end
