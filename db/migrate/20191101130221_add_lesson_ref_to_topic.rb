class AddLessonRefToTopic < ActiveRecord::Migration[6.0]
  def change
    add_column :topics, :default_lesson_id, :bigint
  end
end
