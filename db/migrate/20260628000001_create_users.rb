class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :phone, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :nickname
      t.string :avatar
      t.integer :role, default: 0, null: false

      t.timestamps
    end
  end
end
