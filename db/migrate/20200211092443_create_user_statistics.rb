class CreateUserStatistics < ActiveRecord::Migration[6.0]
  def change
    remove_column :usage_statistics, :time_spent_in_seconds, :integer

    create_table :user_statistics do |t|
      t.integer :questions_answered
      t.references :user, null: false, foreign_key: true
      t.datetime :week_beginning

      t.timestamps
    end
    
    add_index :user_statistics, [:user_id, :week_beginning], :unique => true

  end
end
