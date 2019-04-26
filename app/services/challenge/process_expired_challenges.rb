class Challenge::ProcessExpiredChallenges
  def initialize
    @expired_challenges = Challenge.where('end_date < ?', DateTime.now)
  end

  def call
    award_points
    delete_challenges
  end

  def award_points
    @expired_challenges.each do |c|
      completed_challenges = ChallengeProgress.where('challenge_id = ? AND completed = ?', c, true)
      p 'Removing...' + Challenge.stringify(c)
      completed_challenges.delete_all
    end
  end

  def delete_challenges
    @expired_challenges.delete_all
  end
end
