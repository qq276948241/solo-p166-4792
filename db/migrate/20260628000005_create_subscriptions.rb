class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.integer :frequency, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.date :start_date, null: false
      t.integer :box_size, default: 1, null: false

      t.timestamps
    end

    add_index :subscriptions, [:user_id, :status]
  end
end
