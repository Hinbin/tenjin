class Challenge < ApplicationRecord
  belongs_to :topic
  has_many :challenge_progresses

  scope :by_user, ->(user) { joins(:challenge_progresses).where('challenge_progresses.user_id = ?', user) }

  enum challenge_type: %i[number_correct streak number_of_points]

  def self.create_challenge(subject, challenge_type = nil, multiplier: 1, duration: 7.days)
    @challenge = Challenge.new
    @challenge.topic = Topic.where(subject: subject).order(Arel.sql('RANDOM()')).first
    raise 'no topic available in subject when creating a challenge' if @challenge.topic.nil?

    setup_challenge_type(challenge_type)
    @challenge.start_date = Time.now
    @challenge.end_date = Time.now + duration
    setup_point_value(multiplier: multiplier)

    @challenge.save
    @challenge
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
    def setup_challenge_type(challenge_type)
      @challenge.challenge_type = challenge_type
      generate_random_challenge_type if @challenge.challenge_type.nil?

      case @challenge.challenge_type
      when 'number_correct' then @challenge.number_required = rand(5..10)
      when 'streak' then @challenge.number_required = rand(3..8)
      when 'number_of_points' then @challenge.number_required = rand(2..6) * 10
      end
    end

    def generate_random_challenge_type
      @challenge.challenge_type = Challenge.challenge_types.keys.sample
    end

    def setup_point_value(multiplier: 1)
      @challenge.points = 10 * multiplier
      @challenge.points = (@challenge.points * 3) if @challenge.number_correct? && @challenge.number_required == 10
    end
  end
end
