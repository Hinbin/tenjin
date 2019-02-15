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
    @multiplier = Multiplier.where('score <= ?', @quiz.streak).last
    @percent_complete = (@quiz.num_questions_asked.to_f / @quiz.questions.length.to_f) * 100.to_f
    render Quiz::RenderQuestionType.new(question: @question).call
  end

  # GET /quizzes/new
  def new
    @subject = Subject.where('name = ?', params.permit(:subject).dig(:subject)).first
    authorize Quiz.new(subject: @subject)

    if @subject.blank?
      @subjects = current_user.subjects
      render 'new'
    else
      @topics = @subject.topics.pluck(:name, :id)
      @topics.prepend(['Lucky Dip', 'LD'])
      render 'select_topic'
    end
  end

  # POST /quizzes
  # POST /quizzes.json
  def create
    topic = quiz_params.dig(:picked_topic)
    subject = Subject.find(quiz_params.dig(:subject))
    quiz = Quiz.new(subject: subject)
    authorize quiz, :new?
    return redirect_to new_quiz_path(subject: subject) if topic.blank?

    quiz = Quiz::CreateQuiz.new(user: current_user, topic: topic, subject: subject).call
    redirect_to quiz
  end

  # PATCH/PUT /quizzes/1
  # PATCH/PUT /quizzes/1.json
  def update
    authorize @quiz
    render(json: Quiz::CheckAnswer.new(quiz: @quiz, question: @question, answer_given: answer_params).call)
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
  def answer_params
    params.require(:answer).permit(:id, :short_answer)
  end

  def quiz_params
    params.require(:quiz).permit(:picked_topic, :subject)
  end

  def quiz_not_authorized(exception)
    case exception.query
    when 'new?'
      flash[:alert] = if exception.record.subject.present?
                        ['Invalid subject ', exception.record.subject]
                      else
                        'Subject does not exist'
                      end
    when 'show?'
      flash[:alert] = if exception.record.active?
                        'Quiz does not belong to you'
                      else
                        'This quiz has finished'
                      end
    end
    redirect_to dashboard_path
  end
end
