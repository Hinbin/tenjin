# Craetes a Quiz session object and initialises it appropriately
class CreateQuiz
  def initialize(params)
    @user = params[:user]
  end

  def call
    quiz = Quiz.new
    quiz.user_id = @user.id
    quiz.time_last_answered = Time.current
    quiz.streak = 0
    quiz.answered_correct = 0
    quiz.num_questions_asked = 0
    quiz.active = true

    questions = Question.where('topic_id < ? AND answers_count = ?', 13, 1).order('RANDOM()').take(10)
    quiz.questions = questions

    quiz
  end
end
