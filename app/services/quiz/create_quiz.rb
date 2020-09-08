# frozen_string_literal: true

# Creates a Quiz session object and initialises it appropriately
class Quiz::CreateQuiz < ApplicationService
  def initialize(params)
    @user = params[:user]
    @topic_id = params[:topic]
    @subject_id = params[:subject]
    @lesson_id = params[:lesson]
    @lucky_dip = @topic_id == 'Lucky Dip'
    @subject = Subject.find(@subject_id)
    @topic = Topic.find(@topic_id) unless @lucky_dip
    @lesson = Lesson.find(@lesson_id) unless @lesson_id.blank?
    @quiz = Quiz.new
  end

  def call
    return OpenStruct.new(success?: false, user: @user, errors: 'User not found') unless @user.present?

    initialise_quiz

    unless quiz_cooldown_expired?
      return OpenStruct.new(success?: false, cooldown: @seconds_left,
                            errors: "You need to wait #{@seconds_left} seconds to start another quiz")
    end

    initialise_questions
    check_if_quiz_counts_for_leaderboard
    @quiz.save!
    @user.time_of_last_quiz = Time.current
    @user.save!
    OpenStruct.new(success?: true, quiz: @quiz, errors: nil)
  end

  protected

  def initialise_quiz
    @quiz.user_id = @user.id
    @quiz.time_last_answered = Time.current
    @quiz.streak = 0
    @quiz.answered_correct = 0
    @quiz.num_questions_asked = 0
    @quiz.subject = @subject
    @quiz.active = true
    @quiz.topic = @lucky_dip ? nil : @topic
    @quiz.counts_for_leaderboard = check_if_quiz_counts_for_leaderboard
    @quiz.lesson = @lesson
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
    @quiz.question_order = @quiz.questions.shuffle.pluck(:id)
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
    question_array.shuffle.sample(10)
  end

  def additional_topic_questions
    Question.where(active: true)
            .includes(:topic).references(:topic)
            .select('questions.topic_id, questions.*')
            .where(topics: { active: true, subject_id: @subject_id })
            .order('questions.topic_id, random()')
  end

  def topic_questions
    Question.where(active: true)
            .includes(:topic).references(:topic)
            .select('DISTINCT ON(questions.topic_id) questions.topic_id, questions.*')
            .where(topics: { active: true, subject_id: @subject_id })
            .order('questions.topic_id, random()')
  end

  def lesson_questions
    Question.where(active: true)
            .includes(:lesson)
            .where(lesson: @lesson)
            .order(Arel.sql('RANDOM()'))
            .take(10)
  end

  def subject_questions
    Question.where(active: true, topic: @topic_id)
            .includes(:topic)
            .order(Arel.sql('RANDOM()'))
            .take(10)
  end

  def quiz_cooldown_expired?
    @seconds_left = @user.seconds_left_on_cooldown
    @seconds_left <= 0
  end

  def check_if_quiz_counts_for_leaderboard
    return true if @quiz.topic.nil?

    !UsageStatistic.where(user: @user, topic: @quiz.topic, date: Date.current.all_day)
                   .where('quizzes_started >= 3')
                   .exists?
  end
end
