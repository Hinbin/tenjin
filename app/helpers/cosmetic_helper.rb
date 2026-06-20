# frozen_string_literal: true

# CosmeticHelper — render the Phase 4 equip-slot cosmetics, live and in the shop.
#
# Class-name helpers turn a Customisation.value into the SCSS modifier the skin styles read
# (skins/_cosmetics.scss); the equipped_* readers resolve a user's current choice for live surfaces
# (dashboard header, leaderboard own-row, quiz HUD) with sensible defaults so an unequipped slot
# still renders. Cosmetic-only: none of this affects scoring.
module CosmeticHelper
  # ── class-name mappers (value → SCSS modifier) ───────────────────────────
  def nameplate_class(value) = "tjs-plate--#{value.presence || 'none'}"

  def name_effect_class(value) = "tjs-name-fx--#{value.presence || 'none'}"

  def streak_aura_class(value) = "tjs-streak-aura--#{value.presence || 'default'}"

  # ── live equipped readers (default-safe) ─────────────────────────────────
  def equipped_avatar_glyph(user) = user&.equipped_value(:avatar).presence || 'torii'

  def equipped_avatar_color(user)
    "var(--#{Cosmetic::Catalog.avatar_token(equipped_avatar_glyph(user))})"
  end

  def equipped_nameplate(user) = user&.equipped_value(:nameplate).presence || 'none'

  def equipped_name_effect(user) = user&.equipped_value(:name_effect).presence || 'none'

  def equipped_streak_aura(user) = user&.equipped_value(:streak_aura).presence || 'default'

  def equipped_answer_effect(user) = user&.equipped_value(:answer_effect).presence || 'default'

  # ── shop preview data (read from the catalogs, not the DB) ────────────────
  # A skin's own display font + base-palette accent, so its tile previews in-character even though
  # the page is rendered in a different skin.
  def skin_preview_font(skin) = Theme::SkinCatalog.meta(skin)[:fonts][:display]

  def skin_accent(skin) = Theme::SkinCatalog.palette(skin, 0)[:dark][:n1]

  # The four signature colours of a palette ("skin:index") for a swatch preview.
  def palette_swatch(value)
    skin, index = value.to_s.split(':')
    colours = Theme::SkinCatalog.palette(skin, index)[:dark]
    colours.values_at(:n1, :n2, :n3, :gold)
  end
end
