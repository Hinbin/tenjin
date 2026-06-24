# frozen_string_literal: true

# Shared aggregation helpers for the difficulty-aware gap reports (`ClassGapReport`,
# `StudentGapReport`). Both reports judge performance against the *whole* Tenjin cohort on the same
# items, weighting each question by `Analytics::QuestionDifficulty`. The host service defines the
# question universe via `report_question_stats` (a `{ question_id => { score_sum:, asked: } }` hash);
# everything else — difficulties, the global baseline, per-question metadata, difficulty-weighted
# mastery and cohort standing — is derived here so the two reports stay consistent.
module Analytics::GapReportSupport
  # The cohort-relative heatmap grid (topic cells + per-lesson drill-down) both reports render, built
  # from the primitives defined below. Lives in its own concern to keep each file focused.
  include Analytics::GapGridSupport

  # Difficulty-weighted mastery within this band of the global cohort reads as "on par"; beyond it,
  # above/below. Deliberately generous so small classes are not over-labelled by noise.
  STANDING_THRESHOLD = 0.05
  # Label for questions not yet attached to a lesson, so they still appear in lesson breakdowns.
  NO_LESSON_LABEL = 'No lesson set'

  private

  # The classroom whose subject defines the topic scope. Both hosts hold it in @classroom.
  def classroom
    @classroom
  end

  def topics
    @topics ||= classroom&.subject ? classroom.subject.topics.where(active: true).to_a : []
  end

  def topic_ids
    @topic_ids ||= topics.map(&:id)
  end

  def topic_names
    @topic_names ||= topics.to_h { |topic| [topic.id, topic.name] }
  end

  # The questions this report covers — defined by the host's `report_question_stats`.
  def question_ids
    report_question_stats.keys
  end

  # Hardness per question, from the cohort-wide difficulty engine. One stats query for the batch.
  def difficulties
    @difficulties ||= Analytics::QuestionDifficulty.call(question_ids).difficulties
  end

  # Global (all-school) baseline performance, keyed by question id. The cohort we compare against.
  def global_question_stats
    @global_question_stats ||= QuestionStatistic.where(question_id: question_ids)
                                                .pluck(:question_id, :score_sum, :number_asked)
                                                .to_h { |qid, score_sum, asked| [qid, stat_row(score_sum, asked)] }
  end

  def question_meta
    @question_meta ||= Question.where(id: question_ids)
                               .pluck(:id, :topic_id, :lesson_id, :question_type)
                               .to_h do |id, topic_id, lesson_id, type|
                                 [id, { topic_id: topic_id, lesson_id: lesson_id, question_type: type }]
                               end
  end

  # Lesson titles for every lesson the in-scope questions belong to. Questions with no lesson
  # (lesson_id nil) bucket under a single "No lesson set" label so nothing is silently dropped.
  def lesson_names
    @lesson_names ||= Lesson.where(id: question_meta.values.filter_map { |meta| meta[:lesson_id] }.uniq)
                            .pluck(:id, :title)
                            .to_h
  end

  # Plain-text question stems for the given ids, batch-loaded with their ActionText so report rows can
  # show the actual questions without an N+1 over rich text. Callers pass a small, capped id set.
  def plain_question_texts(ids)
    Question.where(id: ids).with_rich_text_question_text.to_h { |q| [q.id, q.question_text.to_plain_text] }
  end

  # The shared per-question payload every report row carries: where it sits and how hard it is.
  def question_descriptor(qid)
    meta = question_meta[qid] || {}
    diff = difficulties[qid] || {}
    { question_id: qid, topic_id: meta[:topic_id], topic_name: topic_names[meta[:topic_id]],
      question_type: type_name(meta[:question_type]), difficulty: diff[:difficulty], band: diff[:band] }
  end

  # Difficulty-weighted mean score (0..1) over `qids`, drawing per-question means from `source`.
  # Harder questions pull proportionally more weight; nil when nothing in scope was attempted.
  def mastery(qids, source)
    weighted = 0.0
    weight = 0.0
    qids.each do |qid|
      difficulty = difficulties.dig(qid, :difficulty)
      stat = source[qid]
      next unless difficulty && stat && stat[:asked].positive?

      weighted += (stat[:score_sum] / stat[:asked]) * difficulty
      weight += difficulty
    end
    weight.positive? ? (weighted / weight).round(4) : nil
  end

  # Difficulty-weighted standing versus the global cohort, overall and per topic (weakest first).
  # Both reports share this shape; the host supplies the question universe via report_question_stats.
  def cohort_comparison
    by_topic = report_question_stats.keys
                                    .group_by { |qid| question_meta.dig(qid, :topic_id) }
                                    .map { |topic_id, qids| topic_comparison(topic_id, qids) }
                                    .sort_by { |entry| entry[:mastery] || 1.0 }
    { overall: comparison(report_question_stats.keys, report_question_stats), by_topic: by_topic }
  end

  def topic_comparison(topic_id, qids)
    comparison(qids, report_question_stats).merge(topic_id: topic_id, topic_name: topic_names[topic_id])
  end

  # An entity's difficulty-weighted standing over `qids` versus the global cohort.
  def comparison(qids, source)
    own = mastery(qids, source)
    cohort = mastery(qids, global_question_stats)
    delta = own && cohort ? (own - cohort).round(4) : nil
    { mastery: own, cohort_mastery: cohort, delta: delta, standing: standing(delta) }
  end

  def standing(delta)
    return :unknown if delta.nil?
    return :above if delta > STANDING_THRESHOLD
    return :below if delta < -STANDING_THRESHOLD

    :on_par
  end

  def mean(score_sum, asked)
    asked.to_i.positive? ? (score_sum.to_f / asked).round(4) : 0.0
  end

  def stat_row(score_sum, asked)
    { score_sum: score_sum.to_f, asked: asked.to_i }
  end

  # Raw enum integers come back from grouped SQL; map them to the human type name.
  def type_name(type)
    return if type.nil?

    Question.question_types.key(type) || type.to_s
  end
end
