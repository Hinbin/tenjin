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
        top = Leaderboard::BuildLeaderboard.new(nil, id: su.name, school: sc.id).call.sort_by { |s| -s[:score] }
        next unless top.present?

        top_score = top[0].score
        i = 0
        while top[i].present? && top[i].score == top_score
          LeaderboardAward.create(school: sc, subject: su, user: top[i])
          i += 1
        end
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
