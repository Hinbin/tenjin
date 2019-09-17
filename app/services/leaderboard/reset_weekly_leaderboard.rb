class Leaderboard::ResetWeeklyLeaderboard
  def initialize; end

  def call
    award_weekly_winners
    copy_points_to_all_time_scores
    reset_weekly_leaderboard_tables
  end

  def award_weekly_winners
    School.all.each do |sc|
      Subject.all.each do |su|
        top = Leaderboard::BuildLeaderboard.new(nil, id: su.name, school: sc.id).call.first
        LeaderboardAward.create(school: sc, subject: su, user: top) if top.present?
      end
    end
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
