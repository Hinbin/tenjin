# Quizzes Controller
class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz, only: %i[show update]
  before_action :set_question, only: %i[show update]
  before_action :set_subject, only: %i[new create]

  # GET /quizzes
  # GET /quizzes.json
  def index
    @quizzes = policy_scope(Quiz)
    if @quizzes.length.zero?
      redirect_to action: 'new'
    elsif @quizzes.length == 1
      redirect_to @quizzes.first
    else
      redirect_to SelectCorrectQuiz.new(quizzes: @quizzes).call
    end
  end

  # GET /quizzes/1
  # GET /quizzes/1.json
  def show
    authorize @quiz
    @question_number = @quiz.questions
    cookies.encrypted[:user_id] = current_user.id
    render_question
  end

  # GET /quizzes/new
  def new
    @quiz = Quiz.new
    @subject = Subject.where('name = ?', params.permit(:subject).dig(:subject)).first

    if @subject.blank?
      @subjects = current_user.subjects.uniq
      render 'new'
    else
      @topics = @subject.topics
      render 'select_topic'
    end
    authorize @quiz
  end

  # GET /quizzes/1/edit
  def edit; end

  # POST /quizzes
  # POST /quizzes.json
  def create
    @topic = quiz_params.dig(:picked_topic)
    if @topic.blank?
      redirect_to 'new'
      return
    end

    @quiz = CreateQuiz.new(user: current_user, topic: @topic).call
    authorize @quiz
    @quiz.save
    redirect_to @quiz
  end

  # PATCH/PUT /quizzes/1
  # PATCH/PUT /quizzes/1.json
  def update
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

  def render_question
    if @question.answers_count == 1
      render 'question_short_response'
    else
      render 'question_multiple_choice'
    end
  end

  def set_subject
    @subject = params.permit(:subject).dig(:subject)
  end
end
