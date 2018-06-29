# Craetes a Quiz session object and initialises it appropriately
class CreateQuiz
  def initialize(params)
    @user = params[:user]
  end

  def call
    quiz = Quiz.new
    quiz.user_id = @user.id
    quiz.date_started = Date.current
    quiz.time_last_updated = Time.current
    quiz.streak = 0
    quiz.answered_correct = 0
    quiz.num_questions_asked = 0

    questions = Question.where('topic_id < ?', 13).order('RANDOM()').take(10).pluck(:id)
    quiz.questions_asked_id = questions

    quiz
  end
end
