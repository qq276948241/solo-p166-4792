class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.string :province, null: false
      t.string :city, null: false
      t.string :district, null: false
      t.string :detail, null: false
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :addresses, [:user_id, :is_default]
  end
end
