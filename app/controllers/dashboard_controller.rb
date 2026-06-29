# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_user, policy_class: DashboardPolicy # make it so that it checks if the school is permitted
    @subjects = current_user.subjects.uniq

    if current_user.student?
      render_student_dashboard
    else
      teacher_enrollments
      render 'teacher_dashboard'
      current_user
    end
  end

  private

  def render_student_dashboard
    student_homework_progress
    student_topics # resolves @active_subject, which student_challenges filters by
    student_challenges
    student_last_topic
    student_quiz_state
    render 'student_dashboard'
  end

  # Surfaces the two facts the dashboard's quiz-start guard needs (see student_dashboard.js): the
  # user's current active quiz and when their start cooldown lifts. The cooldown is rendered as an
  # absolute expiry (ms) so the countdown stays correct even if the dashboard sits open.
  def student_quiz_state
    @active_quiz = Quiz.where(user: current_user, active: true).order(created_at: :desc).first
    cooldown = current_user.seconds_left_on_cooldown
    @quiz_cooldown_until = (Time.current + cooldown.seconds).to_i * 1000 if cooldown.positive?
  end

  def student_homework_progress
    @homework_progress = HomeworkProgress.includes(homework: [:lesson, { topic: :subject }])
                                         .where('user_id = ? AND ( completed = false OR ( completed = true AND
                                          homeworks.due_date > ? )) ', current_user, 1.week.ago)
                                         .order('homeworks.due_date')
                                         .limit(15)
  end

  def student_challenges
    @challenges = []
    @challenge_progresses = []
    return unless @active_subject

    @challenges = Challenge.includes(topic: :subject)
                           .where(topics: { subject: @active_subject })
                           .where('end_date > ?', Time.current)
    @challenge_progresses = ChallengeProgress.where(challenge: @challenges).where(user: current_user).to_a
  end

  def student_topics
    @active_subject = active_subject_from_param ||
                      @subjects.find { |s| s.name == 'Computer Science' } ||
                      @subjects.first
    return unless @active_subject

    @topics = @active_subject.topics.where(active: true).order(:name)
    load_topic_mastery
  end

  # Preloads the three per-topic inputs the dashboard mastery bar blends (see Topic::MasteryBar):
  # this week's points, lifetime points, and precomputed cross-Tenjin percentile standing.
  def load_topic_mastery
    @topic_scores = TopicScore.where(topic: @topics, user: current_user).index_by(&:topic_id)
    @all_time_topic_scores = AllTimeTopicScore.where(topic: @topics, user: current_user).index_by(&:topic_id)
    @topic_percentiles = TopicPercentile.where(topic: @topics, user: current_user).pluck(:topic_id, :percentile).to_h
  end

  def active_subject_from_param
    return unless params[:active_subject].present?

    @subjects.find { |s| s.id == params[:active_subject].to_i }
  end

  def student_last_topic
    @last_topic = Quiz.where(user: current_user)
                      .where.not(topic: nil)
                      .order(created_at: :desc)
                      .first&.topic
  end

  def teacher_enrollments
    @enrollments = Enrollment.includes(:subject, classroom: :school)
                             .where(user: current_user)
    @other_classrooms = Classroom.where(school: current_user.school)
                                 .includes(:subject)
                                 .where.not(subject: nil)
                                 .where.not(id: @enrollments.select(:classroom_id))
  end
end
