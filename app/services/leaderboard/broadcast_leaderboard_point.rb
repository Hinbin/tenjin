class Leaderboard::BroadcastLeaderboardPoint
  def initialize(topic_score)
    @subject = topic_score.subject
    @user = topic_score.user
    @topic_score = topic_score

    @subject_score = 0
    @message = {}
  end

  def call
    calculate_subject_score
    build_json_data
    broadcast_point
  end

  def broadcast_point
    school = @user.school
    @channel_name = @subject.name + ':'
    @channel_name += if school.school_group_id.present?
                       school.school_group.name
                     else
                       school.name
                     end
    LeaderboardChannel.broadcast_to(@channel_name, @message)
  end

  def build_json_data
    @message = { id: @user.id,
                 forename: @user.forename,
                 surname: @user.surname[0],
                 school_name: @user.school.name,
                 topic: @topic_score.topic.id,
                 topic_score: @topic_score.score,
                 subject_score: @subject_score }
  end

  def calculate_subject_score
    @subject_score = TopicScore.joins(:subject)
                               .where('user_id = ? AND subject_id = ?', @user.id, @subject.id)
                               .sum(:score)
  end
end
