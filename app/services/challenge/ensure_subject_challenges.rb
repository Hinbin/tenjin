# frozen_string_literal: true

# Guarantees every active subject always offers at least MIN_ACTIVE distinct challenges, so a student
# never runs short of quests. Tops up missing slots with a spread of difficulty (an accessible and a
# medium challenge are filled before a premium one) and never repeats a type or topic already active
# for that subject. daily_devotion is global, so it is capped at a single active challenge overall.
class Challenge::EnsureSubjectChallenges < ApplicationService
  MIN_ACTIVE = 3

  # Ordered difficulty tiers. Top-up fills the first tier with no active challenge yet, then the next,
  # so the floor of three always spans easy → medium before reaching premium/skill quests.
  TIERS = [
    %w[number_of_points complete_quizzes cumulative_correct], # accessible
    %w[number_correct streak speed_run],                      # medium
    %w[perfect_quiz big_streak]                               # premium / skill
  ].freeze

  # Multi-session goals get a longer life so they are actually achievable; single-quiz goals rotate
  # daily.
  DURATIONS = {
    'cumulative_correct' => 3.days,
    'complete_quizzes' => 3.days,
    'speed_run' => 2.days,
    'daily_devotion' => 7.days
  }.freeze

  def call
    Subject.where(active: true).find_each { |subject| top_up(subject) }
    ensure_daily_devotion
  end

  private

  def top_up(subject)
    active = active_challenges_for(subject)

    while active.size < MIN_ACTIVE
      challenge = create_for(subject, active)
      break if challenge.nil? || !challenge.persisted?

      active << challenge
    end
  end

  def create_for(subject, active)
    type = next_type(active.map(&:challenge_type))
    topic = available_topic(subject, active.map(&:topic_id))
    return if type.nil? || topic.nil?

    Challenge.create_challenge(subject, type, duration: DURATIONS.fetch(type, 1.day), topic: topic)
  end

  # Prefer a type from a tier that has no active challenge yet (so the floor spreads across
  # difficulty); fall back to any unused standard type once every tier is represented.
  def next_type(used_types)
    unrepresented = TIERS.reject { |tier| tier.intersect?(used_types) }
    pool = (unrepresented.flatten.presence || TIERS.flatten) - used_types
    pool.sample
  end

  # An active topic the subject is not already using for a challenge, falling back to any active topic.
  def available_topic(subject, used_topic_ids)
    scope = subject.topics.where(active: true)
    scope.where.not(id: used_topic_ids).order(Arel.sql('RANDOM()')).first ||
      scope.order(Arel.sql('RANDOM()')).first
  end

  def active_challenges_for(subject)
    Challenge.joins(:topic)
             .where(topics: { subject_id: subject.id })
             .where('end_date > ?', Time.current)
             .to_a
  end

  def ensure_daily_devotion
    return if Challenge.daily_devotion.where('end_date > ?', Time.current).exists?

    subject = Subject.where(active: true).order(Arel.sql('RANDOM()')).first
    return if subject.nil? || subject.topics.where(active: true).none?

    Challenge.create_challenge(subject, 'daily_devotion', duration: DURATIONS.fetch('daily_devotion'))
  end
end
