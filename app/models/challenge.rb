class Challenge < ApplicationRecord
  belongs_to :topic

  enum challenge_type: %i[full_marks streak_of_five get_fifty_points]

  def self.create_challenge(subject, challenge_type = nil)
    challenge = Challenge.new
    challenge.start_date = DateTime.now
    challenge.end_date = DateTime.now + 1.week
    challenge.topic = Topic.where(subject: subject).order(Arel.sql('RANDOM()')).first
    challenge.challenge_type = challenge_type == nil ? Challenge.challenge_types.keys.sample : challenge_type
    challenge.points = challenge.challenge_type == 'full_marks' ? 20 : 10
    challenge.save
    challenge
  end

  def self.stringify(challenge)
    challenge_strings = [
      'Get full marks in any quiz in',
      'Obtain a streak of 5 correct answers for',
      'Score fifty points in'
    ]

    challenge_strings[Challenge.challenge_types[challenge.challenge_type]] + ' ' + challenge.topic.name
  end

end
