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
  # unlock row; everything else needs a CustomisationUnlock. Teachers bypass the points economy
  # entirely (see #owns_all_customisations?), so every slot is theirs for free.
  def owns?(customisation)
    owns_all_customisations? || customisation.free? || customisation_unlocks.exists?(customisation: customisation)
  end

  # Teachers don't earn challenge_points, so the shop economy doesn't apply to them — they get
  # full access to every customisation for free. This is the single entitlement source: both
  # #owns? and Customisation::ShopBoard read it so the Shop and Settings surfaces agree.
  def owns_all_customisations?
    employee?
  end
end
