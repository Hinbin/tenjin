class Challenge::ProcessExpiredChallenges
  def initialize
    @expired_challenges = Challenge.where('end_date > ?', DateTime.now)
  end

  def call
    award_points
    delete_challenges
  end

  def award_points
    @expired_challenges.each do |c|
      completed_challenges = ChallengeProgress.where('challenge_id = ? AND completed = ?', c, true)
      completed_challenges.each do |completed_challenge|
        completed_challenge.user.challenge_points = 0 if completed_challenge.user.challenge_points.nil?
        completed_challenge.user.challenge_points += completed_challenge.challenge.points
        completed_challenge.user.save
      end
      completed_challenges.delete_all
      p 'Removing...' + c.to_s
    end
  end

  def delete_challenges
    @expired_challenges.delete_all
  end
end
