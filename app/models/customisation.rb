# frozen_string_literal: true

class Customisation < ApplicationRecord
  validates :cost, presence: true
  validates :name, presence: true
  validates :value, presence: true
  # The legacy slots 0/1/2 (dashboard_style/leaderboard_icon/subject_image) were retired with the
  # Phase 4 uplift; their integers are left unused so the cosmetic slots keep their numbering.
  # 3/4 are the theme (skin/palette); 5–9 are the cosmetic slots ported from the prototype SHOP_CATS.
  # 10 (light_mode) is a one-off perk, not an equip slot: owning it unlocks the light/dark toggle.
  enum :customisation_type, {
    skin: 3, palette: 4,
    avatar: 5, nameplate: 6, name_effect: 7,
    answer_effect: 8, streak_aura: 9,
    light_mode: 10
  }

  # The Phase 4 equip-slot cosmetics (one active per type) — distinct from the legacy admin styles.
  COSMETIC_SLOTS = %w[skin palette avatar nameplate name_effect answer_effect streak_aura].freeze

  has_many :customisation_unlocks
  has_many :active_customisations

  has_one_attached :image

  before_save :make_unpurchasable_if_retired

  scope :cosmetic, -> { where(customisation_type: COSMETIC_SLOTS) }

  # Free items (decision #2: the skins and each skin's base palette + the cost-0 starter cosmetics)
  # are owned by everyone — no CustomisationUnlock row is created for them. A gated item (req
  # present) is NOT free even at cost 0; it is locked until its achievement is met (decision #4).
  def free?
    req.blank? && cost.to_i.zero?
  end

  # Achievement-gated items are seeded with a non-nil req but stay buyable in v1 (decision #4); the
  # shop treats them as locked/"coming soon" display-only until req → real signals is wired later.
  def gated?
    req.present?
  end

  def make_unpurchasable_if_retired
    return unless retired?

    self.purchasable = false
    self.sticky = false
  end
end
