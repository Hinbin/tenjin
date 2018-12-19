# Creates a Quiz session object and initialises it appropriately
class Quiz::CreateQuiz
  def initialize(params)
    @user = params[:user]
    @topic_id = params[:topic]
    @subject_id = params[:subject]
    @topic = Topic.find(@topic_id) unless @topic_id == 'Lucky Dip'    
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
    @quiz.subject = @topic.subject
    @quiz.active = true
  end

  def initialise_questions
    questions = if @topic_id == 'LD'
                  Question.joins(topic: [:subject]).where('subject_id = ?', @subject_id).order('RANDOM()').take(10)
                else
                  Question.where('topic_id = ?', @topic_id).order('RANDOM()').take(10)
                end

    @quiz.questions = questions
  end
end
