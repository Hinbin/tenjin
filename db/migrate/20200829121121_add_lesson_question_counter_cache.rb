class AddLessonQuestionCounterCache < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :questions_count, :integer
  end
end