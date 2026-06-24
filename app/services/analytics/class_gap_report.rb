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

  # The class summary card (the marketing/case-study asset) only needs the worst few questions.
  HARDEST_QUESTIONS_LIMIT = 10

  # Volume fallback for a topic that has cohort-comparison rows but no attempt rows (defensive — the
  # two are drawn from the same attempts, so this is belt-and-braces).
  EMPTY_TOPIC_VOLUME = { attempts: 0, students: 0 }.freeze

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

  # The per-topic gap grid: difficulty-weighted class mastery against the cohort baseline on the same
  # questions, plus the activity volume behind each figure. Most below the cohort first, so the topics
  # where the class trails comparable students lead; topics with no cohort comparison (unknown
  # standing) sink to the bottom. Merges the cohort comparison with attempt volume so each heatmap
  # cell carries both the signal (mastery / cohort_mastery / delta / standing) and its sample size.
  def topic_gap_grid
    return [] if student_ids.empty? || topic_ids.empty?

    topic_grid_rows.sort_by { |row| [row[:delta] ? 0 : 1, row[:delta] || 0.0] }
  end

  def topic_grid_rows
    volume = topic_volume
    cohort_comparison[:by_topic].map do |row|
      row.merge(volume.fetch(row[:topic_id], EMPTY_TOPIC_VOLUME), lessons: lesson_breakdown(row[:topic_id]))
    end
  end

  # Per-lesson drill-down behind a topic's heatmap cell: the same difficulty-weighted, cohort-relative
  # standing as the topic grid, sliced by the lesson each question sits in (questions with no lesson
  # bucket under NO_LESSON_LABEL). Pure in-memory regrouping of the per-question stats already loaded
  # for the grid — no extra per-topic query — weakest (most below cohort) first.
  def lesson_breakdown(topic_id)
    topic_question_stats(topic_id).group_by { |qid, _| question_meta.dig(qid, :lesson_id) }
                                  .map { |lesson_id, pairs| lesson_gap_row(lesson_id, pairs.to_h) }
                                  .sort_by { |row| [row[:delta] ? 0 : 1, row[:delta] || 0.0] }
  end

  # This topic's slice of the per-question universe: { question_id => { score_sum:, asked: } }.
  def topic_question_stats(topic_id)
    report_question_stats.select { |qid, _| question_meta.dig(qid, :topic_id) == topic_id }
  end

  def lesson_gap_row(lesson_id, lesson_stats)
    comparison(lesson_stats.keys, report_question_stats).merge(
      lesson_id: lesson_id, lesson_name: lesson_names[lesson_id] || NO_LESSON_LABEL,
      attempts: lesson_stats.values.sum { |stat| stat[:asked] }, questions: lesson_stats.size
    )
  end

  # Attempt volume per topic for the grid: { topic_id => { attempts:, students: } }.
  def topic_volume
    StudentQuestionStatistic.joins(question: :topic)
                            .where(user_id: student_ids, topics: { id: topic_ids })
                            .group('topics.id')
                            .pluck('topics.id', Arel.sql('SUM(number_asked)'), Arel.sql('COUNT(DISTINCT user_id)'))
                            .to_h { |id, asked, students| [id, { attempts: asked.to_i, students: students.to_i }] }
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

  # Who is actually practising. Quizzes-started comes from usage_statistics (written live on quiz
  # start); answered-question counts come from the durable student_question_statistics rollup — the
  # same source the rest of the report uses — because usage_statistics.questions_answered is not
  # populated. Scoped to this subject's topics.
  def engagement
    rows = engagement_per_student
    { students_active: rows.size,
      quizzes_started: rows.sum { |entry| entry[:quizzes_started] },
      questions_answered: rows.sum { |entry| entry[:questions_answered] },
      per_student: rows }
  end

  def engagement_per_student
    return [] if student_ids.empty? || topic_ids.empty?

    answered = answered_by_student
    quizzes = quizzes_by_student
    (answered.keys | quizzes.keys).map { |uid| engagement_entry(uid, answered[uid], quizzes[uid]) }
                                  .sort_by { |entry| -entry[:questions_answered] }
  end

  # Answered-question totals per student from the durable rollup: { user_id => { questions_answered:,
  # last_active_at: } }.
  def answered_by_student
    StudentQuestionStatistic.joins(:question)
                            .where(user_id: student_ids, questions: { topic_id: topic_ids })
                            .group(:user_id)
                            .pluck(:user_id, Arel.sql('SUM(number_asked)'), Arel.sql('MAX(last_asked_at)'))
                            .to_h { |uid, asked, last| [uid, { questions_answered: asked.to_i, last_active_at: last }] }
  end

  # Quizzes-started totals per student from usage_statistics: { user_id => { quizzes_started:,
  # last_active_at: } }.
  def quizzes_by_student
    UsageStatistic.where(user_id: student_ids, topic_id: topic_ids)
                  .group(:user_id)
                  .pluck(:user_id, Arel.sql('SUM(quizzes_started)'), Arel.sql('MAX(date)'))
                  .to_h { |uid, started, date| [uid, { quizzes_started: started.to_i, last_active_at: date }] }
  end

  def engagement_entry(uid, answered, quizzes)
    answered ||= {}
    quizzes ||= {}
    { user_id: uid, name: student_names[uid],
      quizzes_started: quizzes[:quizzes_started].to_i,
      questions_answered: answered[:questions_answered].to_i,
      last_active_at: [answered[:last_active_at], quizzes[:last_active_at]].compact.max }
  end

  def student_names
    @student_names ||= User.where(id: student_ids)
                           .pluck(:id, :forename, :surname)
                           .to_h { |id, forename, surname| [id, "#{forename} #{surname}"] }
  end
end
