# frozen_string_literal: true

# Progression — XP / level curve (Plan 01, Phase 2; phase4-shop-data-model.md §6).
#
# Pure, side-effect-free maths so it is trivially unit-testable and shared between the recorder
# (Progression::RecordQuiz) and any read-side display. XP and level are progression DISPLAY only —
# they never affect quiz scoring or grant advantages (cosmetic-only invariant).
module Progression
  module_function

  # XP needed before level 2 begins; each subsequent level needs a widening band (quadratic curve), so
  # the early levels come fast and the later ones take much longer — the classic RPG feel.
  #
  # Calibration — "level 10 ≈ 10 hours of quizzing": XP is earned at Quiz::POINTS_PER_CORRECT (10) per
  # correct answer, and a steady solver answers a mixed quiz at roughly one question every ~20 seconds.
  # 10 hours ≈ 1,800 answers ≈ 18,000 XP. Level 10 begins at the 81st band (xp_for_level(10) = 81·band),
  # so a band ≈ 18,000 / 81 ≈ 220. This is the single knob: if real pace turns out faster/slower, retune
  # XP_PER_BAND (the whole curve scales with it) rather than touching the maths below.
  XP_PER_BAND = 220

  # The level for a given cumulative XP. Inverse of a quadratic curve:
  #   level 1 = 0 xp, level 2 = 220, level 3 = 880, level 4 = 1980, level n = (n-1)^2 * XP_PER_BAND.
  def level_for(total_xp)
    Math.sqrt([total_xp.to_i, 0].max / XP_PER_BAND.to_f).floor + 1
  end

  # Cumulative XP required to reach a given level (the floor of that level's band).
  def xp_for_level(level)
    (([level.to_i, 1].max - 1)**2) * XP_PER_BAND
  end

  # Total XP span of the band between this level and the next — widens as levels climb.
  def band_width(level)
    xp_for_level(level + 1) - xp_for_level(level)
  end

  # XP earned within the current level's band (>= 0), i.e. progress above this level's floor.
  def xp_into_level(total_xp)
    [total_xp.to_i, 0].max - xp_for_level(level_for(total_xp))
  end

  # Whole-number percent (0–100) of the way from the current level toward the next.
  def progress_percent(total_xp)
    ((xp_into_level(total_xp).to_f / band_width(level_for(total_xp))) * 100).round
  end
end
