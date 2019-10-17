# frozen_string_literal: true

# Quizzes Controller
class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz, only: %i[show update]
  before_action :set_question, only: %i[show update]
  before_action :set_css_flavour, only: %i[new]
  before_action :set_subject_and_topic, only: %i[create]
  rescue_from Pundit::NotAuthorizedError, with: :quiz_not_authorized

  def index
    quizzes = policy_scope(Quiz)
    redirect_to Quiz::SelectCorrectQuiz.call(quizzes: quizzes)
  end

  def show
    authorize @quiz
    gon.quiz_id = @quiz.id
    @multiplier = Multiplier.where('score <= ?', @quiz.streak).last
    calculate_percent_completed
    @flagged_question = FlaggedQuestion.where(user: current_user, question: @question).first
    return render Quiz::RenderQuestionType.call(question: @question) if @quiz.active?

    percent_correct = calculate_percent_correct

    flash[:notice] = if percent_correct > 60
                       "Finished!  You got #{percent_correct}%.  Well done!"
                     else
                       "Finished!  You got #{percent_correct}%"
                     end

    redirect_to dashboard_path
  end

  def new
    set_subject
    authorize Quiz.new(subject: @subject)

    if @subject.blank?
      @subjects = current_user.subjects
      render 'new'
    else
      @css_flavour = find_dashboard_style
      @topics = @subject.topics.pluck(:name, :id)
      @topics.prepend(['Lucky Dip', 'Lucky Dip'])
      render 'select_topic'
    end
  end

  def create
    return select_quiz_topic if @topic.blank?

    result = Quiz::CreateQuiz.call(user: current_user, topic: @topic, subject: @subject)
    result.success? ? authorize(result.quiz) : authorize(current_user, :show?, policy_class: UserPolicy)
    return fail_quiz_creation(result) unless result.success?

    @quiz = result.quiz

    redirect_to @quiz
  end

  def update
    authorize @quiz
    render(json: Quiz::CheckAnswer.call(quiz: @quiz, question: @question, answer_given: answer_params))
  end

  private

  def fail_quiz_creation(result)
    flash[:alert] = result.errors
    redirect_to dashboard_path
  end

  def select_quiz_topic
    quiz = Quiz.new(subject: subject)
    authorize quiz, :new?
    redirect_to new_quiz_path(subject: subject)
  end

  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def set_subject
    @subject = Subject.where('name = ?', params.permit(:subject).dig(:subject)).first
  end

  def set_question
    @question = Question.find(@quiz.question_order[@quiz.num_questions_asked - 1])
  end

  def set_css_flavour
    @css_flavour = find_dashboard_style
  end

  def set_subject_and_topic
    @topic = quiz_params.dig(:topic_id)
    @subject = Subject.find(quiz_params.dig(:subject))
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def answer_params
    params.require(:answer).permit(:id, :short_answer)
  end

  def quiz_params
    params.require(:quiz).permit(:topic_id, :subject)
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
      return flash[:alert] = 'Quiz does not belong to you' if exception.record.active?
    end
    redirect_to dashboard_path
  end

  def calculate_percent_completed
    @percent_complete = (@quiz.num_questions_asked / @quiz.questions.length.to_f) * 100.to_f
  end

  def calculate_percent_correct
    return 0 if @quiz.answered_correct.blank? || @quiz.questions.blank?

    ((@quiz.answered_correct / @quiz.questions.length.to_f) * 100.to_f).round
  end
end
