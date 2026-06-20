# frozen_string_literal: true

# Customisation::SetMode — flip a user between light and dark appearance (Plan 01, Phase 4).
#
# The chosen mode is stored on `users.dark_mode`, which Theme::Selection reads when rendering the
# theme. Dark is always allowed; switching to light requires owning the `light_mode` perk
# (Customisation::SeedCosmetics), so students stay locked to dark until they buy it.
#
#   Customisation::SetMode.call(user, false)  # => Result(success:, errors:)
class Customisation::SetMode < ApplicationService
  def initialize(user, dark)
    super()
    @user = user
    @dark = dark
  end

  def call
    return failure('User not found') if @user.nil?
    return failure('Light mode is locked — buy it from the shop first.') if light_requested_but_locked?

    @user.update!(dark_mode: @dark)
    result(success: true, user: @user, errors: nil)
  end

  private

  def light_requested_but_locked?
    !@dark && !light_unlocked?
  end

  def light_unlocked?
    record = Customisation.light_mode.first
    record.present? && @user.owns?(record)
  end

  def failure(message)
    result(success: false, user: @user, errors: message)
  end
end
