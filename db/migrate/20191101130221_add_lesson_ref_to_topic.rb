class AddLessonRefToTopic < ActiveRecord::Migration[6.0]
  def change
    add_reference :topics, :lesson, foreign_key: true
  end
end
