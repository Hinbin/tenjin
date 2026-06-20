# frozen_string_literal: true

# Cosmetic::Catalog — the single source of truth for the purchasable cosmetic slots (Plan 01,
# Phase 4). Ported verbatim from the design prototype's SHOP_CATS
#   design/tenjin-design-system/project/flow/skins/sk-data.jsx
#
# The skin & palette slots are NOT here — their source of truth is Theme::SkinCatalog. This file
# owns the five identity/in-quiz cosmetic slots (avatar, nameplate, name effect, answer effect,
# streak aura). Both the seeder (Customisation::SeedCosmetics) and the read side (shop board +
# live-render helpers) consume this — never re-type the data.
#
# Per item:
#   value : Customisation.value (stable key — the prototype item id)
#   name  : human label
#   cost  : points price (0 = free starter, always owned — decision #2)
#   glyph : GlyphHelper key (avatars only)
#   tok   : palette token tinting the emblem — 'n1'|'n2'|'n3'|'gold' (avatars only)
#   req   : achievement gate text (seeded but still buyable in v1 — decision #4)
module Cosmetic::Catalog
  module_function

  CATEGORIES = {
    'avatar' => {
      en: 'Avatars', jp: '化身', glyph: 'sparkle', blurb: 'The emblem beside your name.',
      items: [
        { value: 'torii',   name: 'Torii',      glyph: 'torii',   tok: 'n1',   cost: 0 },
        { value: 'sakura',  name: 'Blossom',    glyph: 'sakura',  tok: 'n1',   cost: 200 },
        { value: 'heart',   name: 'Sweet',      glyph: 'heart',   tok: 'n3',   cost: 200 },
        { value: 'flame',   name: 'Ember',      glyph: 'flame',   tok: 'n1',   cost: 250 },
        { value: 'bolt',    name: 'Volt',       glyph: 'bolt',    tok: 'gold', cost: 250 },
        { value: 'gem',     name: 'Gem',        glyph: 'gem',     tok: 'n2',   cost: 300 },
        { value: 'sparkle', name: 'Star Pupil', glyph: 'sparkle', tok: 'n2',   cost: 400 },
        { value: 'crown',   name: 'Champion',   glyph: 'crown',   tok: 'gold', cost: 650 },
        { value: 'trophy',  name: 'Victor',     glyph: 'trophy',  tok: 'gold', cost: 0,
          req: 'Finish top 3 on the weekly leaderboard' }
      ]
    },
    'nameplate' => {
      en: 'Nameplates', jp: '名札', glyph: 'tag', blurb: 'A frame behind your name.',
      items: [
        { value: 'none',    name: 'Plain',       cost: 0 },
        { value: 'bar',     name: 'Accent Bar',  cost: 150 },
        { value: 'pixel',   name: 'Pixel Block', cost: 250 },
        { value: 'sticker', name: 'Sticker Pop', cost: 300 },
        { value: 'outline', name: 'Neon Frame',  cost: 350 },
        { value: 'ribbon',  name: 'Gold Ribbon', cost: 0, req: 'Reach a 14-day streak' }
      ]
    },
    'name_effect' => {
      en: 'Name Effects', jp: '効果', glyph: 'star', blurb: 'Colour, glow & shimmer on your name.',
      items: [
        { value: 'none',     name: 'Default',         cost: 0 },
        { value: 'gold',     name: 'Gold',            cost: 150 },
        { value: 'gradient', name: 'Duotone',         cost: 250 },
        { value: 'glow',     name: 'Neon Glow',       cost: 300 },
        { value: 'shimmer',  name: 'Rainbow Shimmer', cost: 700 }
      ]
    },
    'answer_effect' => {
      en: 'Answer Effects', jp: '正解', glyph: 'check', blurb: 'The burst when you nail an answer.',
      items: [
        { value: 'default',   name: 'Skin Default',  cost: 0 },
        { value: 'stars',     name: 'Star Burst',    cost: 250 },
        { value: 'confetti',  name: 'Confetti Rain', cost: 300 },
        { value: 'pixel',     name: 'Pixel Shatter', cost: 300 },
        { value: 'sakura',    name: 'Sakura Storm',  cost: 350 },
        { value: 'fireworks', name: 'Fireworks',     cost: 600 }
      ]
    },
    'streak_aura' => {
      en: 'Streak Aura', jp: '連続', glyph: 'flame', blurb: 'Your streak meter, supercharged.',
      items: [
        { value: 'default', name: 'Flame',       cost: 0 },
        { value: 'blue',    name: 'Blue Fire',   cost: 200 },
        { value: 'frost',   name: 'Frost',       cost: 250 },
        { value: 'volt',    name: 'Lightning',   cost: 300 },
        { value: 'aura',    name: 'Energy Aura', cost: 450 },
        { value: 'rainbow', name: 'Prism',       cost: 0, req: 'Hit a ×5 multiplier' }
      ]
    }
  }.freeze

  # Slot types this catalog owns (skin/palette live in Theme::SkinCatalog).
  def types = CATEGORIES.keys

  def category(type) = CATEGORIES[type.to_s]

  def items(type) = category(type)&.fetch(:items, []) || []

  def item(type, value) = items(type).find { |i| i[:value] == value.to_s }

  # The token ('n1'|'n2'|'n3'|'gold') tinting an avatar emblem; falls back to n1.
  def avatar_token(value) = item('avatar', value)&.fetch(:tok, 'n1') || 'n1'

  # The default (free) value for a slot — index 0 of each category. Used by the default-equip
  # backfill so every student resolves to a valid cosmetic in every slot.
  def default_value(type) = items(type).first&.fetch(:value)
end
