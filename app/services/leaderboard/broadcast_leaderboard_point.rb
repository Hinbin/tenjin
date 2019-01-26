class Leaderboard::BroadcastLeaderboardPoint
  def initialize(subject, user, topic_score)
    @subject = subject
    @user = user
    @topic_score = topic_score
    @channel_name = subject.name, @user.school.name
    @subject_score = 0
    @message = {}
  end

  def call
    calculate_subject_score
    build_json_data
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
