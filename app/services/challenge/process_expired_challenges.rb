class Challenge::ProcessExpiredChallenges
  def initialize
    @expired_challenges = Challenge.where('end_date < ?', Time.current)
  end

  def call
    delete_challenge_progresses
    delete_challenges
  end

  def delete_challenge_progresses
    @expired_challenges.each do |c|
      completed_challenges = ChallengeProgress.where('challenge_id = ?', c)
      p "Removing... #{c.stringify}"
      completed_challenges.delete_all
    end
  end

  def delete_challenges
    @expired_challenges.delete_all
  end
end
