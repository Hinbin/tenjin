# Quizzes Controller
class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz, only: %i[show update]
  before_action :set_question, only: %i[show update]

  # GET /quizzes
  # GET /quizzes.json
  def index
    @quizzes = Quiz.all
  end

  # GET /quizzes/1
  # GET /quizzes/1.json
  def show
    @question_number = @quiz.questions
  end

  # GET /quizzes/new
  def new
    @quiz = Quiz.new
  end

  # GET /quizzes/1/edit
  def edit; end

  # POST /quizzes
  # POST /quizzes.json
  def create
    @quiz = CreateQuiz.new(user: current_user).call

    respond_to do |format|
      if @quiz.save
        format.html { redirect_to @quiz, notice: 'Quiz was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /quizzes/1
  # PATCH/PUT /quizzes/1.json
  def update
    permitted_params = quiz_params
    if permitted_params.dig(:answer_ids).blank?
      render_question
    else
      @answer = params[:question][:answer_ids]
      UpdateQuiz.new(quiz: @quiz, question: @question, answer: @answer).call
      if @quiz.active
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
  def quiz_params
    params.require(:question).permit(:question, :answer_ids)
  end

  def render_question
    if @question.answers.length == 1
      redirect_to action: 'show'
    else
      redirect_to action: 'show'
    end
  end
end
