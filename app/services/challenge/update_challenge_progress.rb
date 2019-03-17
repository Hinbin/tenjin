class Challenge::UpdateChallengeProgress
  def initialize(quiz, challenge_type, number_to_add = 0)
    @quiz = quiz
    @challenges = Challenge.joins(:topic).where('topics.subject_id = ? AND end_date > ? AND challenge_type = ?',
                                                @quiz.subject, DateTime.now, Challenge.challenge_types[challenge_type])
    @number_to_add = number_to_add
  end

  def call
    @challenges.each do |c|
      cp = find_challenge_progress(c)
      case c.challenge_type
      when 'streak' then check_streak(c, cp)
      when 'number_correct' then check_number_correct(c, cp)
      when 'number_of_points' then check_number_of_points(c, cp)
      end
    end
  end

  def check_number_correct(challenge, challenge_progress)
    check_progress_percentage(@quiz.answered_correct.to_f / challenge.number_required.to_f, challenge_progress)
  end

  def check_streak(challenge, challenge_progress)
    check_progress_percentage(@quiz.streak.to_f / challenge.number_required.to_f, challenge_progress)
  end

  def check_number_of_points(challenge, challenge_progress)
    challenge_progress.progress += @number_to_add
    complete_challenge(challenge_progress) if challenge_progress.progress >= challenge.number_required
    challenge_progress.save if challenge_progress.changed?
  end

  def check_progress_percentage(percentage, challenge_progress)
    percentage *= 100
    challenge_progress.progress = percentage if percentage > challenge_progress.progress
    complete_challenge(challenge_progress) if challenge_progress.progress >= 100 && challenge_progress.completed == false
    challenge_progress.save if challenge_progress.changed?
  end

  def complete_challenge(challenge_progress)
    challenge_progress.completed = true
    challenge_progress.user.challenge_points = 0 if challenge_progress.user.challenge_points.nil?
    challenge_progress.user.challenge_points += challenge_progress.challenge.points
    challenge_progress.user.save
  end

  def find_challenge_progress(challenge)
    ChallengeProgress.where('user_id = ? AND challenge_id = ?', @quiz.user, challenge).first_or_create! do |challenge_progress|
      challenge_progress.challenge = challenge
      challenge_progress.user = @quiz.user
      challenge_progress.progress = 0
      challenge_progress.completed = false
    end
  end
end
