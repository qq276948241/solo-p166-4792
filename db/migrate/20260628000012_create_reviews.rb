class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :order, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true
      t.references :vegetable, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :comment, limit: 200

      t.timestamps
    end

    add_index :reviews, [:user_id, :order_item_id], unique: true
    add_index :reviews, [:order_id, :created_at]
    add_index :reviews, [:rating, :created_at]
  end
end
