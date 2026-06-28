class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :weekly_box, null: false, foreign_key: true
      t.string :week_key, null: false
      t.text :address_snapshot, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.datetime :signed_at
      t.string :tracking_number
      t.string :delivery_note
      t.string :sign_remark

      t.timestamps
    end

    add_index :orders, [:user_id, :status]
    add_index :orders, [:weekly_box_id, :status]
    add_index :orders, [:week_key, :status]
  end
end
