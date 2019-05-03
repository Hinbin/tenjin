class AddQuizCountsForLeaderboard < ActiveRecord::Migration[6.0]
  def change
    add_column :quizzes, :counts_for_leaderboard, :boolean
  end
end
