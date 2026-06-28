class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :vegetable, null: false, foreign_key: true
      t.string :vegetable_name_snapshot, null: false
      t.string :vegetable_unit_snapshot, null: false
      t.integer :quantity, default: 1, null: false
      t.decimal :unit_price, precision: 8, scale: 2, null: false

      t.timestamps
    end
  end
end
