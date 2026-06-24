# frozen_string_literal: true

# Lightweight engagement summary for a classroom — the per-class headline for the gap-analysis
# overview page. Deliberately cheap (two grouped queries, no cohort/difficulty work) so the overview
# can list every class a teacher owns without running the full Analytics::ClassGapReport per class.
#
# "Active students" matches ClassGapReport#engagement[:students_active]: enrolled students who have
# practised in this classroom's subject (any StudentQuestionStatistic on the subject's active topics).
#
#   summary = Analytics::ClassGapSummary.call(classroom)
#   summary.student_count    # enrolled students
#   summary.students_active  # of those, how many have practised in the subject
class Analytics::ClassGapSummary < ApplicationService
  def initialize(classroom)
    super()
    @classroom = classroom
  end

  def call
    result(success: true, classroom: @classroom,
           student_count: student_ids.size, students_active: students_active)
  end

  private

  def student_ids
    @student_ids ||= User.where(role: 'student')
                         .joins(:enrollments)
                         .where(enrollments: { classroom_id: @classroom.id })
                         .pluck(:id)
  end

  def topic_ids
    @topic_ids ||= @classroom.subject ? @classroom.subject.topics.where(active: true).pluck(:id) : []
  end

  def students_active
    return 0 if student_ids.empty? || topic_ids.empty?

    StudentQuestionStatistic.joins(:question)
                            .where(user_id: student_ids, questions: { topic_id: topic_ids })
                            .distinct
                            .count(:user_id)
  end
end
