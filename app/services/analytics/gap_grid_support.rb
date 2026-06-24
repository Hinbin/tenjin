# frozen_string_literal: true

# The shared heatmap grid both gap reports render: a difficulty-weighted, cohort-relative standing
# per topic with a per-lesson drill-down. Pulls its primitives (cohort_comparison, comparison,
# question_meta, lesson_names, report_question_stats) from Analytics::GapReportSupport, which mixes
# this in — so Analytics::ClassGapReport and Analytics::StudentGapReport produce identical grids and
# the two surfaces read the same way.
module Analytics::GapGridSupport
  private

  # Per-topic grid, most below the cohort first; topics with no cohort comparison (unknown standing)
  # sink to the bottom. Each cell carries the standing signal (mastery / cohort_mastery / delta /
  # standing) and its attempt volume. Hosts add their own columns (e.g. the class report's
  # distinct-student count) via `topic_grid_extra`.
  def topic_gap_grid
    return [] if question_ids.empty?

    cohort_comparison[:by_topic].map { |row| topic_grid_row(row) }
                                .sort_by { |row| [row[:delta] ? 0 : 1, row[:delta] || 0.0] }
  end

  def topic_grid_row(row)
    topic_id = row[:topic_id]
    attempts = topic_question_stats(topic_id).values.sum { |stat| stat[:asked] }
    row.merge(attempts: attempts, lessons: lesson_breakdown(topic_id)).merge(topic_grid_extra(topic_id))
  end

  # Hook for host-specific grid columns. Default adds nothing; the class report overrides it to carry
  # the distinct-student count behind each topic.
  def topic_grid_extra(_topic_id)
    {}
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
      lesson_id: lesson_id, lesson_name: lesson_names[lesson_id] || Analytics::GapReportSupport::NO_LESSON_LABEL,
      attempts: lesson_stats.values.sum { |stat| stat[:asked] }, questions: lesson_stats.size
    )
  end
end
