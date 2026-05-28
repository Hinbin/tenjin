# frozen_string_literal: true

class School::CompileSchoolStatistics < ApplicationService
  def initialize(school = nil)
    @school = school
  end

  def call
    OpenStruct.new(
      success?: true,
      asked_questions: asked_questions_total,
      asked_questions_weekly: asked_questions_weekly,
      homeworks_completed: homeworks_completed_total,
      homeworks_completed_weekly: homeworks_completed_weekly,
      customisation_unlocks: customisation_unlocks_total,
      customisation_unlocks_weekly: customisation_unlocks_weekly
    )
  end

  private

  def school_scope(relation)
    return relation unless @school.present?

    relation.joins(user: :school).where(users: {school: @school})
  end

  def asked_questions_total
    school_scope(UserStatistic).sum(:questions_answered)
  end

  def asked_questions_weekly
    school_scope(UserStatistic)
      .where(week_beginning: Date.current.beginning_of_week)
      .sum(:questions_answered)
  end

  def homeworks_completed_total
    school_scope(HomeworkProgress.where(completed: true)).count
  end

  def homeworks_completed_weekly
    school_scope(HomeworkProgress.where(completed: true, updated_at: Date.current.beginning_of_week..Time.current)).count
  end

  def customisation_unlocks_total
    school_scope(CustomisationUnlock).count
  end

  def customisation_unlocks_weekly
    school_scope(CustomisationUnlock.where(updated_at: Date.current.beginning_of_week..Time.current)).count
  end
end
