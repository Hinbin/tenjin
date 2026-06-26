# frozen_string_literal: true

# Shared upsert + award helpers for the challenge-progress services. There are two callers:
# Challenge::UpdateChallengeProgress (per correct answer) and Challenge::UpdateCompletionProgress
# (once per finished quiz). Both expect an @quiz ivar and define their own #check_challenge_progress.
#
# Two progress shapes are provided:
#   * upsert_max       — progress only ever rises to the highest value seen (streaks, perfect quiz)
#   * upsert_accumulate — progress grows by an amount each call (points, quiz/answer counts)
module Challenge::ProgressTracking
  private

  def update_each_challenge(scope)
    scope.find_each do |challenge|
      result = check_challenge_progress(challenge)
      next if result.blank?

      award_if_complete(result)
    end
  end

  # The upsert returns [id, completed, awarded]; award only when freshly completed and not yet paid.
  def award_if_complete(result)
    id, completed, awarded = result.rows[0]
    return unless completed == true && awarded == false

    ChallengeProgress.find(id).award_points!
  end

  def upsert_max(value, challenge)
    upsert_progress_row(value, challenge, "GREATEST(challenge_progresses.progress, #{value.to_i})")
  end

  def upsert_accumulate(amount, challenge)
    return if amount.to_i.zero?

    upsert_progress_row(amount, challenge, "challenge_progresses.progress + #{amount.to_i}")
  end

  # Insert the value as the starting progress (completed if it already meets the target), or on
  # conflict apply progress_expr and recompute completion from it. Returns [id, completed, awarded].
  def upsert_progress_row(value, challenge, progress_expr)
    required = challenge.number_required
    on_duplicate = "progress = #{progress_expr}, " \
                   "completed = (challenge_progresses.completed OR (#{progress_expr}) >= #{required})"

    ChallengeProgress.upsert_all(
      [{ progress: value, user_id: @quiz.user.id, challenge_id: challenge.id, completed: value >= required }],
      unique_by: %w[user_id challenge_id],
      on_duplicate: Arel.sql(on_duplicate),
      returning: %w[id completed awarded]
    )
  end

  # Active challenges for the quiz's subject. Callers narrow this by challenge_type.
  def subject_challenges
    Challenge.joins(:topic)
             .where(topics: { subject_id: @quiz.subject })
             .where('end_date > ?', Time.current)
  end
end
