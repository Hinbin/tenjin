class Challenge < ApplicationRecord
  belongs_to :topic
  has_many :challenge_progresses

  scope :by_user, ->(user) { joins(:challenge_progresses).where('challenge_progresses.user_id = ?', user) }

  enum challenge_type: %i[number_correct streak number_of_points]

  def self.create_challenge(subject, challenge_type = nil, multiplier: 1, duration: 7.days)
    @challenge = Challenge.new
    @challenge.start_date = DateTime.now
    @challenge.end_date = DateTime.now + duration
    @challenge.points = 10 * multiplier 
    @challenge.topic = Topic.where(subject: subject).order(Arel.sql('RANDOM()')).first
    raise 'no topic available in subject when creating a challenge' if @challenge.topic.nil?

    setup_challenge_type(challenge_type)
    @challenge.save
    @challenge
  end

  def self.setup_challenge_type(challenge_type)
    @challenge.challenge_type = challenge_type.nil? ? Challenge.challenge_types.keys.sample : challenge_type

    if @challenge.number_correct?
      @challenge.number_required = rand(5..10)
    elsif @challenge.streak?
      @challenge.number_required = rand(3..8)
    elsif @challenge.number_of_points?
      @challenge.number_required = rand(2..6) * 10
    end

    @challenge.points = (@challenge.points * 3) if @challenge.number_correct? && @challenge.number_required == 10
  end

  def self.stringify(challenge)
    challenge_strings = [
      "Get #{challenge.number_required} questions correct in a single quiz in",
      "Obtain a streak of #{challenge.number_required} correct answers for",
      "Score #{challenge.number_required} points in"
    ]

    challenge_strings[Challenge.challenge_types[challenge.challenge_type]] + ' ' + challenge.topic.name
  end
end
