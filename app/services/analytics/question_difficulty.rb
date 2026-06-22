# frozen_string_literal: true

# One source of truth for "how hard is this question". Blends a per-question-type prior with the
# empirical difficulty observed across the *whole* Tenjin cohort (all schools), shrinking toward the
# prior until a question has been asked enough times to trust its own numbers. Partial-credit aware:
# empirical difficulty comes from `score_sum` (0..1 per attempt), not just correct/incorrect.
#
#   Analytics::QuestionDifficulty.call(question)              # single question or id
#   Analytics::QuestionDifficulty.call(Question.where(...))   # relation, one stats query
#   Analytics::QuestionDifficulty.call([1, 2, 3])             # array of ids or questions
#
# Result:
#   .difficulties => { question_id => { difficulty: 0.0..1.0, band: :easy|:medium|:hard }, ... }
#   .difficulty / .band  are also set when called with a single question/id, for convenience.
class Analytics::QuestionDifficulty < ApplicationService
  # Type prior on the 0..1 difficulty scale, hardest-last. MCQ (`multiple`) carries a guessing floor
  # so it reads easiest; free-recall `short_answer` is harder; the structured cloze / grid / ordering
  # formats from the question-types overhaul are hardest. Used verbatim for unsampled questions and
  # as the shrinkage target for lightly-sampled ones. These are deliberate judgement calls.
  TYPE_PRIOR = {
    'multiple' => 0.25,
    'short_answer' => 0.45,
    'fill_blank' => 0.55,
    'ordering' => 0.60,
    'drag_drop' => 0.70,
    'matrix' => 0.70
  }.freeze

  # Prior for a question whose type has no entry above (e.g. the retired :boolean). Mid-scale so an
  # unknown format is neither flattered nor punished.
  DEFAULT_PRIOR = 0.40

  # Empirical evidence overtakes the prior at this many attempts: weight = n / (n + K), so K is the
  # sample size at which prior and reality are trusted 50/50. Deliberately conservative — a handful
  # of attempts should not rebrand a question.
  SHRINKAGE_K = 30

  # Fixed cut points on the blended 0..1 score.
  EASY_MAX = 0.34
  MEDIUM_MAX = 0.67

  def initialize(input)
    super()
    @input = input
  end

  def call
    stats = stats_by_question_id
    difficulties = questions.to_h do |question|
      [question.id, difficulty_for(question, stats[question.id])]
    end

    result(success: true, difficulties: difficulties, **single_shortcuts(difficulties))
  end

  private

  # Blend the type prior with the cohort-wide empirical difficulty, weighting empirical by sample
  # size. Unsampled questions fall straight through to their prior.
  def difficulty_for(question, stat)
    prior = TYPE_PRIOR.fetch(question.question_type, DEFAULT_PRIOR)
    blended = blend(prior, stat).clamp(0.0, 1.0)
    { difficulty: blended, band: band_for(blended) }
  end

  # Sample-size-weighted blend of empirical difficulty toward the type prior. Falls through to the
  # prior when the question has never been asked.
  def blend(prior, stat)
    asked = stat&.number_asked.to_i
    return prior unless asked.positive?

    empirical = 1.0 - (stat.score_sum.to_f / asked)
    weight = asked.to_f / (asked + SHRINKAGE_K)
    (weight * empirical) + ((1 - weight) * prior)
  end

  def band_for(difficulty)
    if difficulty < EASY_MAX
      :easy
    elsif difficulty < MEDIUM_MAX
      :medium
    else
      :hard
    end
  end

  # Single query for every question in scope, keyed by question_id — no N+1 over the batch.
  def stats_by_question_id
    QuestionStatistic.where(question_id: questions.map(&:id)).index_by(&:question_id)
  end

  def questions
    @questions ||= resolve_questions
  end

  def resolve_questions
    case @input
    when ActiveRecord::Relation then @input.to_a
    when Question then [@input]
    when Array then @input.first.is_a?(Question) ? @input : load_questions(@input)
    else load_questions(@input)
    end
  end

  def load_questions(ids)
    Question.where(id: ids).to_a
  end

  # When called with a single question/id, promote that one result's keys to the top level so callers
  # can read `.difficulty` / `.band` directly.
  def single_shortcuts(difficulties)
    return {} unless @input.is_a?(Question) || @input.is_a?(Integer)

    difficulties.values.first || {}
  end
end
