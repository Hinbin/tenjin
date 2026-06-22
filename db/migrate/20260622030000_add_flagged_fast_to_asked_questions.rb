# frozen_string_literal: true

# Anti-cheat: marks a correct answer that came in implausibly fast (below the minimum answer time).
# Such answers are accepted but earn no leaderboard points, and the flag lets teachers spot a student
# (or browser extension) auto-answering known questions. See Quiz::CheckAnswer::MIN_ANSWER_SECONDS.
class AddFlaggedFastToAskedQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :asked_questions, :flagged_fast, :boolean, default: false, null: false
    add_index :asked_questions, :flagged_fast, where: 'flagged_fast'
  end
end
