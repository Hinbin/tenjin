# frozen_string_literal: true

# Runs once per finished quiz (from Progression::RecordQuiz, inside its claimed/idempotent block).
# Handles the challenge types that can only be judged at the end of a quiz, or that track activity
# across quizzes.
class Challenge::UpdateCompletionProgress < ApplicationService
  include Challenge::ProgressTracking

  SUBJECT_TYPES = %w[perfect_quiz complete_quizzes].freeze

  def initialize(quiz)
    super()
    @quiz = quiz
  end

  def call
    update_each_challenge(subject_challenges.where(challenge_type: SUBJECT_TYPES))
    update_each_challenge(daily_devotion_challenges)
  end

  protected

  def check_challenge_progress(challenge)
    case challenge.challenge_type
    when 'perfect_quiz' then upsert_max(perfect_quiz_value, challenge)
    when 'complete_quizzes' then upsert_accumulate(1, challenge)
    when 'daily_devotion' then upsert_max(@quiz.user.streak_days.to_i, challenge)
    end
  end

  # A flawless quiz contributes its length; anything less contributes nothing, so a perfect_quiz
  # only completes when a single quiz of at least number_required questions is answered 100%.
  def perfect_quiz_value
    @quiz.accuracy_percent == 100 ? @quiz.total_questions : 0
  end

  # daily_devotion tracks the global play-day streak, so it counts regardless of which subject the
  # finishing quiz belonged to — scope it to the student's subjects, not the quiz's subject.
  def daily_devotion_challenges
    Challenge.joins(topic: :subject)
             .where(challenge_type: 'daily_devotion')
             .where('end_date > ?', Time.current)
             .where(subjects: { id: @quiz.user.subjects })
  end
end
