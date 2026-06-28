class WalletTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :wallet
  belongs_to :order, optional: true

  enum :txn_type, { recharge: 0, consume: 1, refund: 2 }

  scope :recent, -> { order(created_at: :desc) }
end
