# frozen_string_literal: true

class Challenge::ProcessExpiredChallenges < ApplicationService
  def initialize
    @expired_challenges = Challenge.where(end_date: ...Time.current)
  end

  def call
    delete_challenge_progresses
    delete_challenges
  end

  protected

  def delete_challenge_progresses
    ids = @expired_challenges.pluck(:id)
    Rails.logger.debug { "Removing challenge progresses for expired challenges: #{ids}" }
    ChallengeProgress.where(challenge_id: ids).delete_all
  end

  def delete_challenges
    @expired_challenges.delete_all
  end
end
