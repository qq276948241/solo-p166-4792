class CreateSkipWeeks < ActiveRecord::Migration[8.0]
  def change
    create_table :skip_weeks do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :week_key, null: false
      t.string :reason

      t.timestamps
    end

    add_index :skip_weeks, [:subscription_id, :week_key], unique: true
  end
end
