# frozen_string_literal: true

# Cosmetic::MotionCatalog — per-skin, skin-LOCKED Atmospheres (a drifting animated layer).
# Ported verbatim from the design prototype's SKIN_FX[skin].motions:
#   design/tenjin-design-system/project/flow/skins/sk-cosmetics.jsx
#
# Models exactly like Scenes/palette: one enum slot (`motion`) with composite value "<skin>:<id>",
# resolved against the active skin in Theme::Selection. The first entry of each list is the free
# `none` default. The `id` selects a particle FAMILY rendered by the `motion` Stimulus controller
# (e.g. 'petals', 'rain', 'snow'); ids repeat across skins and reuse the same animation, tinted by
# the skin's palette token. Motion is gated globally by `users.motion_pref` + prefers-reduced-motion.
module Cosmetic::MotionCatalog
  module_function

  MOTIONS = {
    'arcade' => [
      { value: 'none',  name: 'None',       cost: 0 },
      { value: 'stars', name: 'Warp Stars', tok: 'n2', cost: 250 },
      { value: 'rain',  name: 'Code Rain',  tok: 'n1', cost: 300 }
    ],
    'kawaii' => [
      { value: 'none',    name: 'None',            cost: 0 },
      { value: 'bubbles', name: 'Soda Bubbles',    tok: 'n2', cost: 250 },
      { value: 'hearts',  name: 'Floating Hearts', tok: 'n1', cost: 300 }
    ],
    'famicom' => [
      { value: 'none',   name: 'None',         cost: 0 },
      { value: 'snow',   name: 'Pixel Snow',   tok: 'n3', cost: 250 },
      { value: 'clouds', name: '8-bit Clouds', tok: 'n2', cost: 300 }
    ],
    'zen' => [
      { value: 'none',   name: 'None',           cost: 0 },
      { value: 'petals', name: 'Cherry Blossom', tok: 'n1',   cost: 300 },
      { value: 'leaves', name: 'Drifting Leaves', tok: 'n2',  cost: 300 },
      { value: 'embers', name: 'Lantern Glow', tok: 'gold', req: 'Finish a quiz at dawn (5 in a row)' }
    ],
    'pitch' => [
      { value: 'none',    name: 'None',           cost: 0 },
      { value: 'flashes', name: 'Camera Flashes', tok: 'gold', cost: 250 },
      { value: 'ticker',  name: 'Ticker-Tape',    tok: 'n1',   cost: 300 }
    ],
    'manga' => [
      { value: 'none', name: 'None',       cost: 0 },
      { value: 'rain', name: 'Speed Rush', tok: 'n1', cost: 250 },
      { value: 'snow', name: 'Tone Fall',  tok: 'n3', cost: 300 }
    ],
    'street' => [
      { value: 'none',    name: 'None',         cost: 0 },
      { value: 'ticker',  name: 'Sticker Bomb',  tok: 'n1', cost: 250 },
      { value: 'bubbles', name: 'Spray Dots',    tok: 'n2', cost: 300 }
    ]
  }.freeze

  CATEGORY = { en: 'Atmosphere', jp: '動き', glyph: 'sparkle',
               blurb: 'A drifting animated layer, exclusive to this skin. Respects your motion setting.' }.freeze

  def skins = MOTIONS.keys

  def motions_for(skin) = MOTIONS[skin.to_s] || []

  def motion(skin, id) = motions_for(skin).find { |m| m[:value] == id.to_s }

  # The token ('n1'|'n2'|'n3'|'gold') tinting the motion particles; falls back to n1.
  def token(skin, id) = motion(skin, id)&.fetch(:tok, 'n1') || 'n1'

  def default_value(_skin) = 'none'
end
