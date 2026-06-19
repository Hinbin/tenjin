# frozen_string_literal: true

# Progression — XP / level curve (Plan 01, Phase 2; phase4-shop-data-model.md §6).
#
# Pure, side-effect-free maths so it is trivially unit-testable and shared between the recorder
# (Progression::RecordQuiz) and any read-side display. XP and level are progression DISPLAY only —
# they never affect quiz scoring or grant advantages (cosmetic-only invariant).
module Progression
  module_function

  # XP needed before level 2 begins; each subsequent level needs a widening band (quadratic curve).
  XP_PER_BAND = 100

  # The level for a given cumulative XP. Inverse of a quadratic curve:
  #   level 1 = 0 xp, level 2 = 100, level 3 = 400, level 4 = 900, level n = (n-1)^2 * 100.
  def level_for(total_xp)
    Math.sqrt([total_xp.to_i, 0].max / XP_PER_BAND.to_f).floor + 1
  end

  # Cumulative XP required to reach a given level (the floor of that level's band).
  def xp_for_level(level)
    (([level.to_i, 1].max - 1)**2) * XP_PER_BAND
  end
end
