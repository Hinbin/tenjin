class AddFlaggedQuestionCounterCache < ActiveRecord::Migration[6.0]
  def change
    add_column :questions, :flagged_questions_count, :integer
  end
end
