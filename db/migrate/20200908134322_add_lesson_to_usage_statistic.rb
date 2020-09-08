class AddLessonToUsageStatistic < ActiveRecord::Migration[6.0]
  def change
    add_reference :usage_statistics, :lesson, null: true, foreign_key: true
  end
end
