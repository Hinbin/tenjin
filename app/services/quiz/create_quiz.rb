# frozen_string_literal: true

# Creates a Quiz session object and initialises it appropriately
class Quiz::CreateQuiz < ApplicationService
  def initialize(params)
    @user = params[:user]
    @topic_id = params[:topic]
    @subject_id = params[:subject]
    @lucky_dip = @topic_id == 'Lucky Dip'
    @topic = Topic.find(@topic_id) unless @lucky_dip
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
    @quiz.subject = @subject_id
    @quiz.active = true
    @quiz.topic = @lucky_dip ? nil : @topic
    @quiz.counts_for_leaderboard = check_if_quiz_counts_for_leaderboard
  end

  def initialise_questions # rubocop:disable Metrics/MethodLength
    questions = if @lucky_dip
                  # We want an even distribution of topics where possible
                  question_array = []

                  # Keep getting random questions, one from each topic until we have at
                  # least 10 questions

                  question_array += Question.where(active: true)
                                            .includes(:topic).references(:topic)
                                            .select('DISTINCT ON(questions.topic_id) questions.topic_id, questions.*')
                                            .where(topics: { active: true, subject_id: @subject_id })
                                            .order('questions.topic_id, random()')

                  if question_array.length < 10
                    # There are not 10 or more topics so try without getting one from each topic
                    question_array += Question.where(active: true)
                                              .includes(:topic).references(:topic)
                                              .select('questions.topic_id, questions.*')
                                              .where(topics: { active: true, subject_id: @subject_id })
                                              .order('questions.topic_id, random()')
                  end

                  # Get maximum of 10 questions only
                  question_array.shuffle.sample(10)

                else
                  Question.where(active: true, topic: @topic_id)
                          .includes(:topic)
                          .order(Arel.sql('RANDOM()')).take(10)
                end
    @quiz.questions = questions
    @quiz.question_order = @quiz.questions.shuffle.pluck(:id)
  end

  def quiz_cooldown_expired?
    @seconds_left = @user.seconds_left_on_cooldown
    @seconds_left <= 0
  end

  def check_if_quiz_counts_for_leaderboard
    return true if @quiz.topic.nil?

    !UsageStatistic.where(user: @user, topic: @quiz.topic, date: Date.today.all_day)
                   .where('quizzes_started >= 3')
                   .exists?
  end
end
