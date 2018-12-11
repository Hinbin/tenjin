class Quiz::AddLeaderboardPoint
  def initialize(params)
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
    @topic_score = @user.topic_scores.where(topic: @question.topic).first_or_initialize
  end

  def call
    add_to_leaderboard
    broadcast_leaderboard_point
  end

  def add_to_leaderboard
    @multiplier = Multiplier.where('score < ?', @quiz.streak).last.multiplier
    @topic_score.score = 0 if @topic_score.new_record?
    @topic_score.score += @multiplier.to_i
    @topic_score.save
  end

  def broadcast_leaderboard_point
    subject = @quiz.subject
    channel_name = subject.name, @user.school.name
    subject_score = TopicScore.joins(:subject).where('user_id = ? AND subject_id = ?', @user.id, subject.id)
                              .group(:subject_id).sum(:score)[1]
    message = { user: @user.id, topic_score: @topic_score.score, subject_score: subject_score }
    LeaderboardChannel.broadcast_to(channel_name, message)
  end
end
