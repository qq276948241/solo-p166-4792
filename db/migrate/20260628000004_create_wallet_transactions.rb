class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :balance_after, precision: 10, scale: 2, null: false
      t.integer :txn_type, null: false
      t.string :source
      t.string :remark
      t.references :order, foreign_key: true

      t.timestamps
    end

    add_index :wallet_transactions, [:user_id, :created_at]
    add_index :wallet_transactions, [:txn_type, :created_at]
  end
end
