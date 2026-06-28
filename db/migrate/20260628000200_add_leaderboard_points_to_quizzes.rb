# frozen_string_literal: true

class AddLeaderboardPointsToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :leaderboard_points, :integer, default: 0, null: false
  end
end
