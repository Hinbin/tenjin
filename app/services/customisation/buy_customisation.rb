# frozen_string_literal: true

# Customisation::BuyCustomisation — unlock a points-bought item then auto-equip it (Plan 01,
# Phase 4). Charges challenge_points once on first unlock; free items (decision #2) cost nothing
# and create no unlock row. Equipping is delegated to Customisation::EquipCustomisation so the
# slot's prior occupant is cleared (one active per type).
class Customisation::BuyCustomisation < ApplicationService
  def initialize(user, customisation)
    super()
    @user = user
    @customisation = customisation
  end

  def call
    return error_openstruct('Customisation not found') unless @customisation.present?
    return error_openstruct('User not found') unless @user.present?

    # Free items (skins, base palettes, cost-0 starters) are owned by everyone — no unlock row and
    # no charge (decision #2). Everything else: charge once on first unlock, then it stays owned.
    unless @customisation.free?
      unlock = CustomisationUnlock.where(customisation: @customisation, user: @user).first_or_initialize
      if unlock.new_record?
        return error_openstruct('You do not have enough points') unless funds_present?

        deduct_challenge_points
      end
      unlock.save!
    end

    # Buy → auto-equip (matches the prototype). Equipping clears the slot's prior occupant.
    Customisation::EquipCustomisation.call(@user, @customisation)
    result(success: true, user: @user, errors: nil)
  end

  protected

  def deduct_challenge_points
    @user.challenge_points -= @customisation.cost
    @user.save!
  end

  def funds_present?
    @user.challenge_points >= @customisation.cost
  end

  def error_openstruct(error)
    result(success: false, user: @user, errors: error)
  end
end
