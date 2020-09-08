class AddLessonToQuizzes < ActiveRecord::Migration[6.0]
  def change
    add_reference :quizzes, :lesson, null: true, foreign_key: true
  end
end
