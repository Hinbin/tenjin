# frozen_string_literal: true

# Per-student drill-down behind the class gap analysis. Same difficulty-weighted, cohort-relative
# lens as `Analytics::ClassGapReport`, narrowed to one student: their topic- and lesson-level
# strengths and gaps, how they stand against the whole Tenjin cohort, and the hard questions they
# nonetheless aced (strengths). The classroom supplies the subject/topic scope.
#
#   report = Analytics::StudentGapReport.call(user, classroom)
#   report.topic_breakdown   # [{ topic_id:, topic_name:, mean_score:, attempts: }, ...] weakest first
#   report.lesson_breakdown  # [{ lesson_id:, lesson_name:, mean_score:, attempts: }, ...] weakest first
#   report.cohort_comparison # { overall: { mastery:, cohort_mastery:, delta:, standing: }, by_topic: [...] }
#   report.strengths         # [<question_descriptor> + student_score:, cohort_score:] hardest-aced first
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
      topic_breakdown: topic_breakdown,
      lesson_breakdown: lesson_breakdown,
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

  # Per-topic mean score for this student, weakest first.
  def topic_breakdown
    report_question_stats.group_by { |qid, _| question_meta.dig(qid, :topic_id) }
                         .map { |topic_id, pairs| topic_row(topic_id, pairs) }
                         .sort_by { |topic| topic[:mean_score] }
  end

  def topic_row(topic_id, pairs)
    score_sum = pairs.sum { |_, stat| stat[:score_sum] }
    asked = pairs.sum { |_, stat| stat[:asked] }
    { topic_id: topic_id, topic_name: topic_names[topic_id], mean_score: mean(score_sum, asked), attempts: asked }
  end

  # Per-lesson mean score for this student, weakest first — the reteach list, keyed to the lessons
  # teachers actually deliver. Questions with no lesson bucket under NO_LESSON_LABEL.
  def lesson_breakdown
    report_question_stats.group_by { |qid, _| question_meta.dig(qid, :lesson_id) }
                         .map { |lesson_id, pairs| lesson_row(lesson_id, pairs) }
                         .sort_by { |lesson| lesson[:mean_score] }
  end

  def lesson_row(lesson_id, pairs)
    score_sum = pairs.sum { |_, stat| stat[:score_sum] }
    asked = pairs.sum { |_, stat| stat[:asked] }
    { lesson_id: lesson_id, lesson_name: lesson_names[lesson_id] || NO_LESSON_LABEL,
      mean_score: mean(score_sum, asked), attempts: asked }
  end

  # Global mean score (0..1) for a question, or nil when the cohort has not attempted it.
  def cohort_mean(qid)
    cohort = global_question_stats[qid]
    return unless cohort && cohort[:asked].positive?

    (cohort[:score_sum] / cohort[:asked]).round(4)
  end

  # Hard questions the student nonetheless aced — hardest first. The "give them credit" list.
  def strengths
    report_question_stats.filter_map { |qid, stat| strength_row(qid, stat) }
                         .sort_by { |row| -(row[:difficulty] || 0.0) }
                         .first(PRIORITY_LIMIT)
  end

  def strength_row(qid, stat)
    student_score = (stat[:score_sum] / stat[:asked]).round(4)
    band = difficulties.dig(qid, :band)
    return if student_score < STRENGTH_MIN_SCORE || band.nil? || band == :easy

    question_descriptor(qid).merge(student_score: student_score, cohort_score: cohort_mean(qid))
  end
end
