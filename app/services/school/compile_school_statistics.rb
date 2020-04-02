# frozen_string_literal: true

class School::CompileSchoolStatistics < ApplicationService
  def initialize(school = nil)
    @school = school
  end

  def call
    compile_asked_questions
    compile_homeworks_completed
    compile_customisation_unlocks
    OpenStruct.new(success?: true,
                   asked_questions: @a_q,
                   asked_questions_weekly: @a_q_w,
                   homeworks_completed: @h_c,
                   homeworks_completed_weekly: @h_c_w,
                   customisation_unlocks: @c_u,
                   customisation_unlocks_weekly: @c_u_w)
  end

  def compile_asked_questions
    @a_q = UserStatistic
    @a_q = @a_q.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @a_q = @a_q.sum(:questions_answered)

    @a_q_w = UserStatistic
    @a_q_w = @a_q_w.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @a_q_w = @a_q_w.where(week_beginning: Date.current.beginning_of_week).sum(:questions_answered)
  end

  def compile_homeworks_completed
    @h_c = HomeworkProgress.where(completed: true)
    @h_c = @h_c.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @h_c = @h_c.count

    @h_c_w = HomeworkProgress.where(completed: true, updated_at: Date.current.beginning_of_week..Date.current)
    @h_c_w = @h_c_w.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @h_c_w = @h_c_w.count
  end

  def compile_customisation_unlocks
    @c_u = CustomisationUnlock
    @c_u = @c_u.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @c_u = @c_u.count

    @c_u_w = CustomisationUnlock.where(updated_at: Date.current.beginning_of_week..Date.current)
    @c_u_w = @c_u_w.joins(user: :school).where(users: { school: @school }) unless @school.blank?
    @c_u_w = @c_u_w.count
  end
end
