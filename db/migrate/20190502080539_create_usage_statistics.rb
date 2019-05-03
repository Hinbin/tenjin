class CreateUsageStatistics < ActiveRecord::Migration[6.0]
  def change
    create_table :usage_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, foreign_key: true
      t.datetime :date
      t.integer :quizzes_started
      t.integer :time_spent_in_seconds
      t.integer :questions_answered

      t.timestamps
    end
  end
end
