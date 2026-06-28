# frozen_string_literal: true

class Multiplier < ApplicationRecord
  validates :score, presence: true, uniqueness: true
  validates :multiplier, presence: true

  # The multiplier in effect at a given streak: the highest tier whose `score` threshold the streak has
  # reached. This is the single source of truth shared by the HUD "mult" meter and the scoring path
  # (Quiz::CheckAnswer / Quiz::AddLeaderboardPoint), so what the student is shown is exactly what their
  # answer earns. Falls back to ×1 when no tiers are configured.
  def self.for_streak(streak)
    where('score <= ?', streak.to_i).order(score: :desc).pick(:multiplier) || 1
  end
end
