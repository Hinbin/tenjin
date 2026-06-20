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
    student_challenges
    student_topics
    student_last_topic
    render 'student_dashboard'
  end

  def student_homework_progress
    @homework_progress = HomeworkProgress.includes(homework: [:lesson, { topic: :subject }])
                                         .where('user_id = ? AND ( completed = false OR ( completed = true AND
                                          homeworks.due_date > ? )) ', current_user, 1.week.ago)
                                         .order('homeworks.due_date')
                                         .limit(15)
  end

  def student_challenges
    @challenges = Challenge.includes(topic: :subject)
                           .where(topics: { subject: @subjects })
    @challenge_progresses = ChallengeProgress.where(challenge: @challenges).where(user: current_user).to_a
  end

  def student_topics
    @active_subject = active_subject_from_param ||
                      @subjects.find { |s| s.name == 'Computer Science' } ||
                      @subjects.first
    return unless @active_subject

    @topics = @active_subject.topics.where(active: true).order(:name)
    @topic_scores = TopicScore.where(topic: @topics, user: current_user).index_by(&:topic_id)
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
    @enrollments = Enrollment.includes(:classroom, :subject)
                             .where(user: current_user)
    @other_classrooms = Classroom.where(school: current_user.school)
                                 .includes(:subject)
                                 .where.not(subject: nil)
                                 .where.not(id: @enrollments.select(:classroom_id))
  end
end
