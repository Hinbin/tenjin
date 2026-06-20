# frozen_string_literal: true

# Equippable — a user's equipped cosmetics (Plan 01, Phase 4).
#
# A "slot" is a customisation_type; at most one active per type (enforced by
# Customisation::EquipCustomisation). These reads are what Theme::Selection and the live-cosmetic
# view helpers consume.
module Equippable
  extend ActiveSupport::Concern

  included do
    has_many :active_customisations
    has_many :customisation_unlocks
  end

  # The equipped Customisation for a slot (e.g. :skin, :avatar), or nil.
  def equipped(type)
    slot = Customisation.customisation_types.fetch(type.to_s)
    active_customisations.joins(:customisation)
                         .find_by(customisations: { customisation_type: slot })
                         &.customisation
  end

  # The equipped Customisation.value for a slot (e.g. "arcade" / "arcade:1" / "torii"), or nil.
  def equipped_value(type)
    equipped(type)&.value
  end

  # Decision #2: free items (skins, base palettes, cost-0 starters) are owned by everyone with no
  # unlock row; everything else needs a CustomisationUnlock.
  def owns?(customisation)
    customisation.free? || customisation_unlocks.exists?(customisation: customisation)
  end
end
