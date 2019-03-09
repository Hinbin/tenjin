class Challenge::UpdateChallengeProgress
  def initialize(quiz)
    @quiz = quiz
    @challenges = Challenge.joins(:topic).where(' topics.subject_id = ? AND end_date > ?', @quiz.subject, DateTime.now)
  end

  def call
    @challenges.each do |c|
      case c.challenge_type
      when 'full_marks' then check_full_marks(c)
      end
    end
  end

  def check_full_marks(challenge)
    cp = ChallengeProgress.where('user_id = ? AND challenge_id = ?', @quiz.user, challenge).first_or_create! do |cp|
      cp.challenge = challenge
      cp.user = @quiz.user
      cp.progress = 0
      cp.completed = false
    end

    percentage = (@quiz.answered_correct.to_f / @quiz.num_questions_asked.to_f) * 100
    cp.progress = percentage if percentage > cp.progress
    cp.completed = true if percentage == 100
    cp.save if cp.changed?
  end
end
