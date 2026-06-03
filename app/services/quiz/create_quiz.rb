# frozen_string_literal: true

# Creates a Quiz session object and initialises it appropriately
class Quiz::CreateQuiz < ApplicationService
  def initialize(params)
    super()
    @user = params[:user]
    @topic_id = params[:topic]
    @subject = params[:subject]
    @lesson = (Lesson.find(params[:lesson]) if params[:lesson].present?)
    @lucky_dip = @topic_id == 'Lucky Dip'
    @topic = Topic.find(@topic_id) unless @lucky_dip
    @quiz = Quiz.new
  end

  def call
    return result(success: false, user: @user, errors: 'User not found') unless @user.present?

    context = instrumentation_context
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    ActiveSupport::Notifications.instrument('quiz.create.tenjin', context) do |payload|
      create_locked_quiz(payload)
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::StatementInvalid => e
    AppErrorReporter.report(e, context: context.merge(failure_class: e.class.name,
                                                      duration_ms: duration_since(started_at)))
    result(success: false, errors: 'Sorry, Tenjin could not start that quiz. Please try again.')
  end

  protected

  def create_locked_quiz(payload)
    @user.with_lock do
      initialise_quiz

      cooldown_result = check_cooldown(payload)
      return cooldown_result if cooldown_result.present?

      initialise_questions

      question_result = check_question_selection(payload)
      return question_result if question_result.present?

      save_quiz(payload)
    end
  end

  def check_cooldown(payload)
    return if quiz_cooldown_expired?

    payload[:success] = false
    payload[:failure_class] = 'cooldown'
    result(success: false,
           cooldown: @seconds_left,
           errors: "You need to wait #{@seconds_left} seconds to start another quiz")
  end

  def check_question_selection(payload)
    payload[:selected_question_count] = @quiz.question_order.length
    return if @quiz.question_order.present?

    payload[:success] = false
    payload[:failure_class] = 'no_questions'
    result(success: false, errors: 'No active questions are available for this quiz.')
  end

  def save_quiz(payload)
    @quiz.counts_for_leaderboard = check_if_quiz_counts_for_leaderboard
    @quiz.save!
    UsageStatistic::RecordQuizStart.call(@quiz)
    @user.update!(time_of_last_quiz: Time.current)
    payload[:success] = true
    result(success: true, quiz: @quiz, errors: nil)
  end

  def initialise_quiz
    @quiz.user_id = @user.id
    @quiz.time_last_answered = Time.current
    @quiz.streak = 0
    @quiz.answered_correct = 0
    @quiz.num_questions_asked = 0
    @quiz.subject = @subject
    @quiz.lesson = @lesson
    @quiz.active = true
    @quiz.topic = @lucky_dip ? nil : @topic
  end

  def initialise_questions
    questions = if @lucky_dip
                  lucky_dip_questions
                elsif @lesson
                  lesson_questions
                else
                  subject_questions
                end
    @quiz.questions = questions
    @quiz.question_order = questions.map(&:id)
  end

  def lucky_dip_questions
    # We want an even distribution of topics where possible
    question_array = []

    # Keep getting random questions, one from each topic until we have at least 10 questions
    question_array += topic_questions

    if question_array.length < 10
      # There are not 10 or more topics so try without getting one from each topic
      question_array += additional_topic_questions
    end

    # Get maximum of 10 questions only
    question_array.shuffle.take(10)
  end

  def additional_topic_questions
    sample_questions(active_subject_questions, 10)
  end

  def topic_questions
    Topic.where(active: true, subject_id: @subject.id).pluck(:id).filter_map do |topic_id|
      sample_questions(Question.where(active: true, topic_id:), 1).first
    end
  end

  def lesson_questions
    sample_questions(Question.where(active: true, lesson: @lesson), 10)
  end

  def subject_questions
    sample_questions(Question.where(active: true, topic: @topic_id), 10)
  end

  def active_subject_questions
    Question.joins(:topic)
            .where(active: true)
            .where(topics: { active: true, subject_id: @subject.id })
  end

  def sample_questions(scope, limit)
    ids = scope.pluck(:id).sample(limit)
    Question.where(id: ids).index_by(&:id).then { |questions| ids.filter_map { |id| questions[id] } }
  end

  def quiz_cooldown_expired?
    @seconds_left = @user.seconds_left_on_cooldown
    @seconds_left <= 0
  end

  def check_if_quiz_counts_for_leaderboard
    return true if @quiz.topic.nil?

    if @quiz.lesson
      check_lesson_attempts
    else
      check_topic_attempts
    end
  end

  def check_lesson_attempts
    !UsageStatistic.where(user: @user, topic: @quiz.topic, lesson: @quiz.lesson, date: Date.current.all_day)
                   .where('quizzes_started >= 1')
                   .exists?
  end

  def check_topic_attempts
    !UsageStatistic.where(user: @user, topic: @quiz.topic, date: Date.current.all_day)
                   .where('quizzes_started >= 3')
                   .exists?
  end

  def instrumentation_context
    { user_id: @user&.id,
      subject_id: @subject&.id,
      topic_id: @lucky_dip ? nil : @topic_id,
      lesson_id: @lesson&.id,
      lucky_dip: @lucky_dip }
  end

  def duration_since(started_at)
    return nil unless started_at

    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
  end
end
