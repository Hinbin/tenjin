# frozen_string_literal: true

# Blends the two halves of a topic's dashboard progress bar into a single 0–100 fill:
#
#   * mastery  (MASTERY_WEIGHT) — how much the student has got right in this topic, as accumulated
#                                 leaderboard points (all-time + the current, not-yet-banked week),
#                                 capped at MASTERY_TARGET.
#   * peer     (PEER_WEIGHT)    — the student's precomputed percentile standing against every other
#                                 Tenjin student who has practised the topic.
#
# Pure calculator: callers pass the three already-loaded values so the dashboard stays free of N+1s.
class Topic::MasteryBar < ApplicationService
  MASTERY_WEIGHT = 0.60
  PEER_WEIGHT    = 0.40
  MASTERY_TARGET = 500

  def initialize(weekly_score:, all_time_score:, percentile:)
    super()
    @weekly_score   = weekly_score.to_i
    @all_time_score = all_time_score.to_i
    @percentile     = percentile.to_i
  end

  def call
    blended = (MASTERY_WEIGHT * mastery_fraction) + (PEER_WEIGHT * peer_fraction)
    (blended * 100).round.clamp(0, 100)
  end

  protected

  def mastery_fraction
    points = @weekly_score + @all_time_score
    [points.to_f / MASTERY_TARGET, 1.0].min
  end

  def peer_fraction
    @percentile.clamp(0, 100) / 100.0
  end
end
