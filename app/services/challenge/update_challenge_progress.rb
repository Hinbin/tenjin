# frozen_string_literal: true

# Runs once per correct answer (from Quiz::AddLeaderboardPoint). Handles the challenge types that
# accrue while a quiz is in progress. Completion-only types live in Challenge::UpdateCompletionProgress.
class Challenge::UpdateChallengeProgress < ApplicationService
  include Challenge::ProgressTracking

  PER_ANSWER_TYPES = %w[number_correct streak big_streak number_of_points cumulative_correct speed_run].freeze

  def initialize(quiz, number_to_add = 0, question_topic = nil, answer_seconds = nil)
    super()
    @quiz = quiz
    @number_to_add = number_to_add
    @question_topic = question_topic
    @answer_seconds = answer_seconds
  end

  def call
    update_each_challenge(subject_challenges.where(challenge_type: PER_ANSWER_TYPES))
  end

  protected

  def check_challenge_progress(challenge)
    case challenge.challenge_type
    when 'number_correct' then topic_max(@quiz.answered_correct, challenge)
    when 'streak' then topic_max(@quiz.streak, challenge)
    when 'big_streak' then topic_max(@quiz.max_streak, challenge)
    when 'number_of_points' then number_of_points_progress(challenge)
    when 'cumulative_correct' then upsert_accumulate(1, challenge)
    when 'speed_run' then upsert_accumulate(speedy_answer, challenge)
    end
  end

  # number_correct / streak / big_streak only count toward the challenge's own topic.
  def topic_max(value, challenge)
    return unless @quiz.topic == challenge.topic

    upsert_max(value, challenge)
  end

  def number_of_points_progress(challenge)
    return unless number_of_points_match?(challenge)

    upsert_accumulate(@number_to_add, challenge)
  end

  # A topic challenge matches its own topic (or the answered question's topic on a lucky dip);
  # a daily challenge matches any topic in its subject.
  def number_of_points_match?(challenge)
    challenge.topic == @quiz.topic ||
      challenge.topic == @question_topic ||
      (challenge.daily && challenge.topic.subject == @question_topic&.subject)
  end

  # 1 if this answer was given inside the speed window, otherwise 0 (no progress).
  def speedy_answer
    @answer_seconds.present? && @answer_seconds <= Challenge::SPEED_THRESHOLD ? 1 : 0
  end
end
