# frozen_string_literal: true

# CosmeticTrial — try-before-you-buy rate limiting (see CustomisationsController#preview).
#
# A student can preview an unowned cosmetic live, but only one trial window per cooldown. The window
# start is persisted on `users.cosmetic_trial_at` so it survives logout — a session-only timer would
# reset on every login and defeat the point. Switching the previewed item within an active trial is
# free; that distinction lives in the controller.
module CosmeticTrial
  extend ActiveSupport::Concern

  # How long after starting a trial before another can be started.
  COSMETIC_TRIAL_COOLDOWN = 1.hour

  # Can the student start a NEW cosmetic trial right now?
  def cosmetic_trial_available?
    cosmetic_trial_at.nil? || cosmetic_trial_at <= COSMETIC_TRIAL_COOLDOWN.ago
  end

  # When the cooldown lifts (nil if a trial can be started now).
  def cosmetic_trial_available_at
    return nil if cosmetic_trial_available?

    cosmetic_trial_at + COSMETIC_TRIAL_COOLDOWN
  end
end
