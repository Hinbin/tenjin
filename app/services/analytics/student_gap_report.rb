# frozen_string_literal: true

# Per-student drill-down behind the class gap analysis. Same difficulty-weighted, cohort-relative
# lens as `Analytics::ClassGapReport`, narrowed to one student: their topic- and lesson-level
# standing against the whole Tenjin cohort (rendered as the same heatmap the class surface uses), how
# they stand overall, and the hard questions they nonetheless aced (strengths). The classroom
# supplies the subject/topic scope.
#
#   report = Analytics::StudentGapReport.call(user, classroom)
#   report.topic_gap_grid    # [{ topic_id:, topic_name:, mastery:, cohort_mastery:, delta:, standing:,
#                            #    attempts:, lessons: [{ lesson_id:, lesson_name:, mastery:,
#                            #    cohort_mastery:, delta:, standing:, attempts:, questions: }, ...] }, ...]
#                            #    most below cohort first (shared with ClassGapReport, minus the class
#                            #    grid's student-count column)
#   report.cohort_comparison # { overall: { mastery:, cohort_mastery:, delta:, standing: }, by_topic: [...] }
#   report.strengths         # [<question_descriptor> + question_text:, student_score:, cohort_score:]
#                            #   hardest-aced first
class Analytics::StudentGapReport < ApplicationService
  include Analytics::GapReportSupport

  PRIORITY_LIMIT = 10
  # A question only counts as a "strength" worth surfacing when the student scores at least this and
  # the item is not an easy one — beating an easy question is not noteworthy.
  STRENGTH_MIN_SCORE = 0.8

  def initialize(user, classroom)
    super()
    @user = user
    @classroom = classroom
  end

  def call
    result(
      success: true,
      user: @user,
      classroom: @classroom,
      topic_gap_grid: topic_gap_grid,
      cohort_comparison: cohort_comparison,
      strengths: strengths
    )
  end

  private

  # This student's per-question performance across the subject — the report's question universe.
  def report_question_stats
    @report_question_stats ||= compute_report_question_stats
  end

  def compute_report_question_stats
    return {} if topic_ids.empty?

    StudentQuestionStatistic.joins(:question)
                            .where(user_id: @user.id, questions: { topic_id: topic_ids })
                            .where('number_asked > 0')
                            .pluck(:question_id, :score_sum, :number_asked)
                            .to_h { |qid, score_sum, asked| [qid, stat_row(score_sum, asked)] }
  end

  # Global mean score (0..1) for a question, or nil when the cohort has not attempted it.
  def cohort_mean(qid)
    cohort = global_question_stats[qid]
    return unless cohort && cohort[:asked].positive?

    (cohort[:score_sum] / cohort[:asked]).round(4)
  end

  # Hard questions the student nonetheless aced — hardest first. The "give them credit" list. Each row
  # carries the actual question stem (batch-loaded for the capped top set, no N+1) so teachers see the
  # specific questions, not just their type.
  def strengths
    rows = report_question_stats.filter_map { |qid, stat| strength_row(qid, stat) }
                                .sort_by { |row| -(row[:difficulty] || 0.0) }
                                .first(PRIORITY_LIMIT)
    texts = plain_question_texts(rows.pluck(:question_id))
    rows.map { |row| row.merge(question_text: texts[row[:question_id]]) }
  end

  def strength_row(qid, stat)
    student_score = (stat[:score_sum] / stat[:asked]).round(4)
    band = difficulties.dig(qid, :band)
    return if student_score < STRENGTH_MIN_SCORE || band.nil? || band == :easy

    question_descriptor(qid).merge(student_score: student_score, cohort_score: cohort_mean(qid))
  end
end
