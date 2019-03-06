class Challenge::ProcessExpiredChallenges
  def initialize()
    @expired_challanges
  end

  def call
    find_expired_challenges
    award_points
    delete_challenges
  end

  def find_expired_challenges
    @expired_challenges = Challenge.where('end_date < ?', DateTime.now)
  end

  def award_points
    @expired_challenges.each do |c|
      #@completed_challenges = ChallengeProgress.where('challenge_id = ? AND completed = ?', c, true)
    end
  end

  def delete_challenges
    @expired_challenges.delete_all
  end

end
