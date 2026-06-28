class CreateWeeklyBoxes < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_boxes do |t|
      t.string :week_key, null: false, index: { unique: true }
      t.date :week_start_date, null: false
      t.date :week_end_date, null: false
      t.datetime :lock_at, null: false
      t.boolean :is_locked, default: false, null: false
      t.decimal :price, precision: 8, scale: 2, default: 0, null: false
      t.integer :stock, default: 0, null: false
      t.integer :sold_count, default: 0, null: false
      t.string :name
      t.text :description
      t.string :cover_image

      t.timestamps
    end
  end
end
