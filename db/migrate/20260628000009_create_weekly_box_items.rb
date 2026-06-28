class CreateWeeklyBoxItems < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_box_items do |t|
      t.references :weekly_box, null: false, foreign_key: true
      t.references :vegetable, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false

      t.timestamps
    end

    add_index :weekly_box_items, [:weekly_box_id, :vegetable_id], unique: true
  end
end
