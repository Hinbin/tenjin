class Leaderboard::ResetWeeklyLeaderboard
  def initialize; end

  def call
    copy_points_to_all_time_scores
    reset_weekly_leaderboard_tables
  end

  def copy_points_to_all_time_scores
    TopicScore.all.each do |ts|
      atts = AllTimeTopicScore.where(user: ts.user, topic: ts.topic).first_or_initialize
      atts.score = (atts.new_record? ? ts.score : atts.score + ts.score)
      atts.save!
    end
  end

  def reset_weekly_leaderboard_tables
    TopicScore.destroy_all
  end
end
