class CreateVegetables < ActiveRecord::Migration[8.0]
  def change
    create_table :vegetables do |t|
      t.string :name, null: false
      t.string :unit, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.text :description
      t.string :image
      t.integer :stock, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
