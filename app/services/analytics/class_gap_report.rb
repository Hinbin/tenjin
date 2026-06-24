# frozen_string_literal: true

# Difficulty-aware, cohort-relative gap analysis for a whole classroom — the flagship teacher surface
# from the monetisation plan. Answers: where is this class weak, which questions trip them up, how do
# they stand against every other Tenjin student on the *same* items (difficulty-weighted, not raw %),
# and who is actually practising.
#
# Reads the durable per-student rollup (`student_question_statistics`) joined through the classroom's
# enrolled students, scoped to the classroom subject's active topics. Every aggregate is a SQL
# `GROUP BY` — never a query per student. The global baseline is `question_statistics`; question
# hardness comes from `Analytics::QuestionDifficulty`.
#
#   report = Analytics::ClassGapReport.call(classroom)
#   report.topic_gap_grid          # [{ topic_id:, topic_name:, mastery:, cohort_mastery:, delta:,
#                                  #    standing:, attempts:, students:, lessons: [{ lesson_id:,
#                                  #    lesson_name:, mastery:, cohort_mastery:, delta:, standing:,
#                                  #    attempts:, questions: }, ...] }, ...] most below cohort first
#   report.hardest_questions       # [{ question_id:, topic_id:, topic_name:, question_type:,
#                                  #    question_text:, difficulty:, band:, class_mean_score:,
#                                  #    attempts: }, ...]
#   report.cohort_comparison       # { overall: { mastery:, cohort_mastery:, delta:, standing: },
#                                  #   by_topic: [ <overall keys> + topic_id:, topic_name:, ... ] }
#   report.engagement              # { students_active:, quizzes_started:, questions_answered:,
#                                  #   per_student: [{ user_id:, name:, quizzes_started:,
#                                  #                   questions_answered:, last_active_at: }, ...] }
class Analytics::ClassGapReport < ApplicationService
  include Analytics::GapReportSupport
  include Analytics::ClassEngagementSupport

  # The class summary card (the marketing/case-study asset) only needs the worst few questions.
  HARDEST_QUESTIONS_LIMIT = 10

  def initialize(classroom)
    super()
    @classroom = classroom
  end

  def call
    result(
      success: true,
      classroom: @classroom,
      student_count: student_ids.size,
      topic_gap_grid: topic_gap_grid,
      hardest_questions: hardest_questions,
      cohort_comparison: cohort_comparison,
      engagement: engagement
    )
  end

  private

  # Per-question class aggregates — the question universe every other section is built from.
  def report_question_stats
    @report_question_stats ||= compute_report_question_stats
  end

  def compute_report_question_stats
    return {} if student_ids.empty? || topic_ids.empty?

    StudentQuestionStatistic.joins(:question)
                            .where(user_id: student_ids, questions: { topic_id: topic_ids })
                            .group(:question_id)
                            .pluck(:question_id, Arel.sql('SUM(score_sum)'), Arel.sql('SUM(number_asked)'))
                            .to_h { |qid, score_sum, asked| [qid, stat_row(score_sum, asked)] }
  end

  def student_ids
    @student_ids ||= User.where(role: 'student').joins(:enrollments)
                         .where(enrollments: { classroom_id: @classroom.id }).pluck(:id)
  end

  # The class grid carries one column the per-student grid does not: how many distinct students sit
  # behind each topic's figure (the sample size). The difficulty-weighted, cohort-relative standing
  # and per-lesson drill-down all come from the shared `topic_gap_grid` in Analytics::GapReportSupport.
  def topic_grid_extra(topic_id)
    { students: topic_student_counts.fetch(topic_id, 0) }
  end

  # Distinct students who have attempted each in-scope topic: { topic_id => student_count }.
  def topic_student_counts
    @topic_student_counts ||= StudentQuestionStatistic.joins(question: :topic)
                                                      .where(user_id: student_ids, topics: { id: topic_ids })
                                                      .group('topics.id')
                                                      .distinct.count(:user_id)
  end

  # The questions the class found hardest (by cohort difficulty), with the class's own mean and the
  # actual question text on each (batch-loaded via plain_question_texts — the ≤10 stems, no N+1).
  def hardest_questions
    ids = report_question_stats.keys.sort_by { |qid| -(difficulties.dig(qid, :difficulty) || 0.0) }
                                    .first(HARDEST_QUESTIONS_LIMIT)
    texts = plain_question_texts(ids)
    ids.map { |qid| hardest_question_row(qid, texts[qid]) }
  end

  def hardest_question_row(qid, text)
    stat = report_question_stats[qid]
    question_descriptor(qid).merge(question_text: text, attempts: stat[:asked],
                                   class_mean_score: mean(stat[:score_sum], stat[:asked]))
  end
end
