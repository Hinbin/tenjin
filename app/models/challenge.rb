# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :topic
  has_many :challenge_progresses, dependent: :destroy

  scope :has_progress, ->(user) { includes(:challenge_progresses).where('challenge_progresses.user_id = ?', user) }
  scope :has_no_progress, -> { includes(:challenge_progresses).where(challenge_progresses: { id: nil }) }

  enum :challenge_type, {
    number_correct: 0, streak: 1, number_of_points: 2,
    perfect_quiz: 3, cumulative_correct: 4, complete_quizzes: 5, big_streak: 6,
    daily_devotion: 7, speed_run: 8
  }

  # A correct answer counts toward a speed_run only if it was given within this many seconds.
  SPEED_THRESHOLD = 10

  # Types that the random picker / weekly generator may pick by default. big_streak is premium-only
  # and daily_devotion is a global one-off, so both are injected explicitly rather than sampled.
  STANDARD_TYPES = %w[
    number_correct streak number_of_points perfect_quiz cumulative_correct complete_quizzes speed_run
  ].freeze

  # Inclusive range rand() draws number_required from, per type.
  NUMBER_REQUIRED_RANGE = {
    'number_correct' => 5..10,
    'streak' => 3..8,
    'number_of_points' => 40..60,
    'perfect_quiz' => 5..10,
    'cumulative_correct' => 15..25,
    'complete_quizzes' => 3..5,
    'big_streak' => 12..15,
    'daily_devotion' => 3..5,
    'speed_run' => 10..20
  }.freeze

  # Points = unit value * number_required (then * multiplier), tuned so ~3-4 decent challenges buy a
  # 300pt recolour. perfect_quiz is a flat reward (see setup_point_value).
  POINTS_PER_UNIT = {
    'number_correct' => 10,
    'streak' => 15,
    'number_of_points' => 1,
    'cumulative_correct' => 4,
    'complete_quizzes' => 25,
    'big_streak' => 15,
    'daily_devotion' => 30,
    'speed_run' => 5
  }.freeze
  PERFECT_QUIZ_POINTS = 80

  DESCRIPTIONS = {
    'number_correct' => 'Get %<n>d questions correct in a single quiz',
    'streak' => 'Obtain a streak of %<n>d correct answers',
    'number_of_points' => 'Score %<n>d points',
    'perfect_quiz' => 'Complete a quiz of at least %<n>d questions with no mistakes',
    'cumulative_correct' => 'Answer %<n>d questions correctly',
    'complete_quizzes' => 'Complete %<n>d quizzes',
    'big_streak' => 'Build a massive streak of %<n>d correct answers',
    'daily_devotion' => 'Play on %<n>d days in a row',
    'speed_run' => 'Answer %<n>d questions correctly in under %<secs>d seconds each'
  }.freeze

  # rubocop:disable Metrics/ParameterLists
  def self.create_challenge(subject, challenge_type = nil, multiplier: 1, duration: 7.days, daily: false, topic: nil)
    challenge = Challenge.new start_date: Time.current, end_date: duration.from_now
    challenge.daily = daily
    challenge.topic = topic || Topic.where(active: true).order(Arel.sql('RANDOM()')).find_by(subject: subject)

    setup_challenge_type(challenge, challenge_type)
    setup_point_value(challenge, multiplier: multiplier)
    challenge.save
    challenge
  end
  # rubocop:enable Metrics/ParameterLists

  def stringify
    return challenge_string if daily_devotion?
    return "#{challenge_string} today in #{topic.subject.name}" if daily

    "#{challenge_string} in #{topic.name} for #{topic.subject.name}"
  end

  class << self
    def setup_challenge_type(challenge, challenge_type)
      challenge.challenge_type = challenge_type.presence || random_challenge_type
      challenge.challenge_type = 'number_of_points' if challenge.daily
      challenge.number_required = rand(NUMBER_REQUIRED_RANGE.fetch(challenge.challenge_type))
    end

    def random_challenge_type
      STANDARD_TYPES.sample
    end

    def setup_point_value(challenge, multiplier: 1)
      base = if challenge.perfect_quiz?
               PERFECT_QUIZ_POINTS
             else
               POINTS_PER_UNIT.fetch(challenge.challenge_type) * challenge.number_required
             end

      challenge.points = base * multiplier
    end
  end

  def challenge_string
    format(DESCRIPTIONS.fetch(challenge_type), n: number_required, secs: SPEED_THRESHOLD)
  end
end
