# frozen_string_literal: true

# Customisation::EquipCustomisation — equip one owned item into its slot (Plan 01, Phase 4).
#
# A "slot" is a customisation_type: at most one active per type. Because the type lives on the
# joined customisations row (not on active_customisations) this is enforced here rather than with
# a DB constraint — on equip we delete the current occupant of the slot inside a transaction, then
# create the new active row.
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
      clear_slot
      ActiveCustomisation.create!(user: @user, customisation: @customisation)
    end
    result(success: true, user: @user, errors: nil)
  end

  private

  def clear_slot
    ActiveCustomisation.where(user: @user)
                       .joins(:customisation)
                       .where(customisations: { customisation_type: @customisation.customisation_type })
                       .delete_all
  end

  def failure(message)
    result(success: false, user: @user, errors: message)
  end
end
