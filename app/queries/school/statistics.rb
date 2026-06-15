# frozen_string_literal: true

# Aggregates platform usage statistics, optionally scoped to a single school.
# Constructed cheaply; each method runs its query once and memoizes the result.
class School::Statistics
  def initialize(school = nil)
    @school = school
  end

  def asked_questions
    @asked_questions ||= school_scope(UserStatistic).sum(:questions_answered)
  end

  def asked_questions_weekly
    @asked_questions_weekly ||= school_scope(UserStatistic)
      .where(week_beginning: Date.current.beginning_of_week)
      .sum(:questions_answered)
  end

  def homeworks_completed
    @homeworks_completed ||= school_scope(HomeworkProgress.where(completed: true)).count
  end

  def homeworks_completed_weekly
    @homeworks_completed_weekly ||= school_scope(
      HomeworkProgress.where(completed: true, updated_at: Date.current.beginning_of_week..Time.current)
    ).count
  end

  def customisation_unlocks
    @customisation_unlocks ||= school_scope(CustomisationUnlock).count
  end

  def customisation_unlocks_weekly
    @customisation_unlocks_weekly ||= school_scope(
      CustomisationUnlock.where(updated_at: Date.current.beginning_of_week..Time.current)
    ).count
  end

  private

  def school_scope(relation)
    return relation if @school.nil?

    relation.joins(user: :school).where(users: {school: @school})
  end
end
