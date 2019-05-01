class AddTimeOfLastQuiz < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :time_of_last_quiz, :datetime
  end
end
