class Quiz::AddLeaderboardPoint
  def initialize(params)
    @quiz = params[:quiz]
    @user = @quiz.user
    @question = params[:question]
    @topic_score = @user.topic_scores.where(topic: @question.topic).first_or_initialize
  end

  def call
    add_points
    Leaderboard::BroadcastLeaderboardPoint.new(@quiz.subject, @user, @topic_score).call
  end

  def add_points
    @multiplier = Multiplier.where('score < ?', @quiz.streak).last.multiplier

    @topic_score.score = 0 if @topic_score.new_record?
    @topic_score.score += @multiplier.to_i
    @topic_score.save
  end

end
