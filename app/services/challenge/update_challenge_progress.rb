class Challenge::UpdateChallengeProgress < ApplicationService
  def initialize(quiz, challenge_type, number_to_add = 0, question_topic = nil)
    @quiz = quiz
    @challenges = Challenge.joins(:topic).where('topics.subject_id = ? AND end_date > ? AND challenge_type = ?',
                                                @quiz.subject, Time.current, Challenge.challenge_types[challenge_type])
    @number_to_add = number_to_add
    @question_topic = question_topic
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

  def check_number_correct(challenge, progress)
    return unless @quiz.topic == challenge.topic

    check_progress_percentage(@quiz.answered_correct.to_f / challenge.number_required, progress)
  end

  def check_streak(challenge, progress)
    return unless @quiz.topic == challenge.topic

    check_progress_percentage(@quiz.streak.to_f / challenge.number_required.to_f, progress)
  end

  def check_number_of_points(challenge, progress)
    return unless @question_topic == challenge.topic

    progress.progress += @number_to_add
    complete_challenge(progress) if progress.progress >= challenge.number_required
    progress.save if progress.changed?
  end

  def check_progress_percentage(percentage, progress)
    percentage *= 100
    progress.progress = percentage if percentage > progress.progress
    complete_challenge(progress) if progress.progress >= 100 && progress.completed == false
    progress.save if progress.changed?
  end

  def complete_challenge(progress)
    progress.completed = true
    progress.user.challenge_points = 0 if progress.user.challenge_points.nil?
    progress.user.challenge_points += progress.challenge.points
    progress.user.save
  end

  def find_challenge_progress(challenge)
    ChallengeProgress.where('user_id = ? AND challenge_id = ?', @quiz.user, challenge)
                     .first_or_create! do |progress|
      progress.challenge = challenge
      progress.user = @quiz.user
      progress.progress = 0
      progress.completed = false
    end
  end
end
