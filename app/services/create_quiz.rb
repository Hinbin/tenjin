# Craetes a Quiz session object and initialises it appropriately
class CreateQuiz
  def initialize(params)
    @user = params[:user]
    @topic = params[:topic]
    @quiz = Quiz.new
  end

  def call
    initialise_quiz
    initialise_questions

    @quiz
  end

  def initialise_quiz
    @quiz.user_id = @user.id
    @quiz.time_last_answered = Time.current
    @quiz.streak = 0
    @quiz.answered_correct = 0
    @quiz.num_questions_asked = 0
    @quiz.classroom_id = 2 #Do later!
    @quiz.active = true
  end

  def initialise_questions
    questions = if @topic.blank?
                  Question.where('topic_id < ?', 13).order('RANDOM()').take(10)
                else
                  Question.where('topic_id = ?', @topic).order('RANDOM()').take(10)
                end

    @quiz.questions = questions
  end
end
