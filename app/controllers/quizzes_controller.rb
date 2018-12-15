# Quizzes Controller
class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz, only: %i[show update]
  before_action :set_question, only: %i[show update]
  rescue_from Pundit::NotAuthorizedError, with: :quiz_not_authorized

  # GET /quizzes
  # GET /quizzes.json
  def index
    quizzes = policy_scope(Quiz)
    redirect_to Quiz::SelectCorrectQuiz.new(quizzes: quizzes).call
  end

  # GET /quizzes/1
  # GET /quizzes/1.json
  def show
    authorize @quiz
    gon.quiz_id = @quiz.id
    cookies.encrypted[:user_id] = current_user.id
    @multiplier = Multiplier.where('score <= ?', @quiz.streak).last
    @percent_complete = (@quiz.num_questions_asked.to_f / @quiz.questions.length.to_f) * 100.to_f
    render_question
  end

  # GET /quizzes/new
  def new
    authorize Quiz.new

    @subject = Subject.where('name = ?', params.permit(:subject).dig(:subject)).first

    if @subject.blank?
      @subjects = current_user.subjects
      render 'new'
    else
      @topics = @subject.topics
      render 'select_topic'
    end
  end

  # GET /quizzes/1/edit
  def edit; end

  # POST /quizzes
  # POST /quizzes.json
  def create
    quiz = Quiz.new
    authorize quiz, :new?
    topic = quiz_params.dig(:picked_topic)
    subject = quiz_params.dig(:subject)
    return redirect_to new_quiz_path(subject: subject) if topic.blank?

    quiz = Quiz::CreateQuiz.new(user: current_user, topic: topic).call
    quiz.save
    redirect_to quiz
  end

  # PATCH/PUT /quizzes/1
  # PATCH/PUT /quizzes/1.json
  def update
    authorize @quiz
    check_answer = Quiz::CheckAnswer.new(quiz: @quiz, question: @question, answer_given: answer_params).call
    render(json: check_answer)
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
  def answer_params
    params.require(:answer).permit(:id, :short_answer)
  end

  def quiz_params
    params.require(:quiz).permit(:picked_topic, :subject)
  end

  def quiz_not_authorized
    redirect_to '/dashboard/'
  end
end
