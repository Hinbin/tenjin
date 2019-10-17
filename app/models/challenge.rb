# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :topic
  has_many :challenge_progresses

  scope :by_user, ->(user) { joins(:challenge_progresses).where('challenge_progresses.user_id = ?', user) }

  enum challenge_type: %i[number_correct streak number_of_points]

  def self.create_challenge(subject, challenge_type = nil, multiplier: 1, duration: 7.days)
    challenge = Challenge.new start_date: Time.current, end_date: duration.from_now
    challenge.topic = Topic.order(Arel.sql('RANDOM()')).find_by(subject: subject)

    setup_challenge_type(challenge, challenge_type)
    setup_point_value(challenge, multiplier: multiplier)

    challenge.save
    challenge
  end

  def stringify
    challenge_strings = [
      "Get #{number_required} questions correct in a single quiz",
      "Obtain a streak of #{number_required} correct answers",
      "Score #{number_required} points"
    ]

    "#{challenge_strings[Challenge.challenge_types[challenge_type]]} in #{topic.name} for #{topic.subject.name}"
  end

  class << self
    def setup_challenge_type(challenge, challenge_type)
      challenge.challenge_type = challenge_type.presence || random_challenge_type

      case challenge.challenge_type
      when 'number_correct' then challenge.number_required = rand(5..10)
      when 'streak' then challenge.number_required = rand(3..8)
      when 'number_of_points' then challenge.number_required = rand(20..60)
      end
    end

    def random_challenge_type
      Challenge.challenge_types.keys.sample
    end

    def setup_point_value(challenge, multiplier: 1)
      point_value = 10 * multiplier
      point_value *= 3 if challenge.number_correct? && challenge.number_required == 10

      challenge.points = point_value
    end
  end
end
