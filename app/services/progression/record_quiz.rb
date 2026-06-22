# frozen_string_literal: true

# Progression::RecordQuiz — update streak / XP / level on quiz completion (Plan 01, Phase 2).
#
# Called from the quiz-finish path (QuizzesController#show once a quiz is no longer active).
# IDEMPOTENT: claims the quiz atomically via progression_recorded_at so a refresh / double-submit
# of a finished quiz cannot inflate streak or XP. Keeps the spendable wallet
# (users.challenge_points) untouched — XP/level are separate progression and grant no advantage
# (cosmetic-only invariant).
class Progression::RecordQuiz < ApplicationService
  def initialize(params)
    super()
    @user = params[:user]
    @quiz = params[:quiz]
  end

  def call
    return result(success: false, recorded: false) unless quiz_claimed?

    @user.with_lock do
      update_streak
      @user.xp += @quiz.points_earned
      @user.level = Progression.level_for(@user.xp)
      @user.save!
    end

    # streak_days is now up to date, so completion-only challenges (perfect quiz, complete N quizzes,
    # daily devotion) can be judged exactly once for this quiz.
    Challenge::UpdateCompletionProgress.call(@quiz)

    result(success: true, recorded: true)
  end

  private

  # Atomically mark this quiz as recorded; only the winning caller proceeds. Returns false if the
  # quiz was already recorded (a replay) so streak/XP are applied exactly once.
  def quiz_claimed?
    Quiz.where(id: @quiz.id, progression_recorded_at: nil)
        .update_all(progression_recorded_at: Time.current)
        .positive?
  end

  # yesterday → +1, today → unchanged, otherwise → reset to 1.
  def update_streak
    today = Date.current
    last  = @user.last_streak_day

    @user.streak_days =
      if last == today then [@user.streak_days, 1].max
      elsif last == today - 1 then @user.streak_days + 1
      else 1
      end
    @user.last_streak_day = today
  end
end
