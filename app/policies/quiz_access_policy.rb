class QuizAccessPolicy
  attr_reader :user, :post

  def initialize(user, quiz)
    @user = user
    @quiz = quiz
  end

  def update?
    @user.id == @quiz.user_id
  end
end
