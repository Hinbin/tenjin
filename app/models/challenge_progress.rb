# frozen_string_literal: true

class ChallengeProgress < ApplicationRecord
  belongs_to :challenge
  belongs_to :user

  validates :user, uniqueness: { scope: [:challenge] }

  # Pay out the challenge's points to the student's spendable wallet, exactly once.
  def award_points!
    return if awarded

    update!(awarded: true)
    user.update!(challenge_points: user.challenge_points.to_i + challenge.points)
  end
end
