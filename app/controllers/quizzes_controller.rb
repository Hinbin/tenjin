# Quizzes Controller
class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz, only: %i[show update]
  before_action :set_question, only: %i[show update]
  before_action :set_subject, only: %i[new create]

  # GET /quizzes
  # GET /quizzes.json
  def index
    quizzes = policy_scope(Quiz)
    if quizzes.length.zero?
      redirect_to action: 'new'
    elsif quizzes.length == 1
      redirect_to quizzes.first
    else
      redirect_to Quiz::SelectCorrectQuiz.new(quizzes: quizzes).call
    end
  end

  # GET /quizzes/1
  # GET /quizzes/1.json
  def show
    authorize @quiz
    cookies.encrypted[:user_id] = current_user.id
    render_question
  end

  # GET /quizzes/new
  def new
    quiz = Quiz.new
    subject = Subject.where('name = ?', params.permit(:subject).dig(:subject)).first

    if subject.blank?
      render 'new'
    else
      topics = @subject.topics
      render 'select_topic'
    end
    authorize quiz
  end

  # GET /quizzes/1/edit
  def edit; end

  # POST /quizzes
  # POST /quizzes.json
  def create
    topic = quiz_params.dig(:picked_topic)
    return redirect_to 'new' if topic.blank?

    quiz = Quiz::CreateQuiz.new(user: current_user, topic: topic).call
    authorize quiz
    quiz.save
    redirect_to quiz
  end

  # PATCH/PUT /quizzes/1
  # PATCH/PUT /quizzes/1.json
  def update
    authorize @quiz
    return render_question unless CheckAnswer.new(params).call
    AskedQuestion.where('quiz_id = ? AND question_id = ?', @quiz.id, @question.id)
    

    #check if question has already been answer
      #if so move them on
    #if not, check to see if we have an answer

    if question_params.dig(:answer_ids).blank?
      render_question
    else
      UpdateQuiz.new(quiz: @quiz, question: @question,
                     user: current_user, answer_given: question_params.dig(:answer_ids)).call
      if @quiz.active
        set_question
        render_question
      else
        redirect_to action: 'new'
      end
    end
  end

  private

  def render_question
    render Quiz::RenderQuestionType.new(question: @question).call
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def set_question
    @question = @quiz.questions.limit(1).offset(@quiz.num_questions_asked).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def question_params
    params.require(:question).permit(:question, :answer_ids, :picked_topic)
  end

  def quiz_params
    params.require(:quiz).permit(:picked_topic)
  end

  def set_subject
    @subject = params.permit(:subject).dig(:subject)
  end
end
