# frozen_string_literal: true

# Customisation::EquipCustomisation — equip one owned item into its slot (Plan 01, Phase 4).
#
# A "slot" is a customisation_type: at most one active per type. Because the type lives on the
# joined customisations row (not on active_customisations) this is enforced here rather than with
# a DB constraint — on equip we delete the current occupant of the slot inside a transaction, then
# create the new active row.
#
# A palette belongs to a skin (its value is "<skin>:<index>"), so equipping a palette also equips
# that skin — picking a colour scheme implicitly switches you to its skin. This is the only way the
# UI switches skins now (the standalone "Equip skin" button was removed): selecting any of a skin's
# palettes flips the whole look to that skin.
#
#   Customisation::EquipCustomisation.call(user, customisation)  # => Result(success:, errors:)
class Customisation::EquipCustomisation < ApplicationService
  def initialize(user, customisation)
    super()
    @user = user
    @customisation = customisation
  end

  def call
    return failure('Customisation not found') if @customisation.nil?
    return failure('You do not own this item') unless @user.owns?(@customisation)

    ActiveCustomisation.transaction do
      equip(@customisation)
      equip(skin_for_palette) if @customisation.palette?
    end
    result(success: true, user: @user, errors: nil)
  end

  private

  # Clear the slot's current occupant, then activate the given customisation.
  def equip(customisation)
    return if customisation.nil?

    clear_slot(customisation.customisation_type)
    ActiveCustomisation.create!(user: @user, customisation: customisation)
  end

  def clear_slot(type)
    ActiveCustomisation.where(user: @user)
                       .joins(:customisation)
                       .where(customisations: { customisation_type: type })
                       .delete_all
  end

  # The skin a palette belongs to (palette value is "<skin>:<index>"); nil if it can't be resolved.
  def skin_for_palette
    skin_value = @customisation.value.to_s.split(':').first
    Customisation.skin.find_by(value: skin_value)
  end

  def failure(message)
    result(success: false, user: @user, errors: message)
  end
end
