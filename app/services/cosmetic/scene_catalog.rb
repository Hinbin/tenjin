# frozen_string_literal: true

# Cosmetic::SceneCatalog — per-skin, skin-LOCKED Scenes (a signature backdrop motif).
# Ported verbatim from the design prototype's SKIN_FX[skin].scenes:
#   design/tenjin-design-system/project/flow/skins/sk-cosmetics.jsx
#
# A Scene is bought with points, equipped per-skin, and only available while its skin is active.
# It models exactly like `palette`: one enum slot (`scene`) whose Customisation.value is the
# composite "<skin>:<id>" (e.g. "zen:tree"), resolved against the active skin in Theme::Selection.
# The first entry of each list is the free `none` default (cost 0, owned by everyone).
#
# Per item:
#   value : the scene id (the value stored is "<skin>:<id>")
#   name  : human label
#   cost  : points price (0 = free starter / the 'none' default)
#   tok   : palette token tinting the motif — 'n1'|'n2'|'n3'|'gold'
#   req   : achievement gate text (seeded but not directly buyable in v1)
#
# Rendering: SceneArtHelper draws the inline-SVG motif where one exists; otherwise a tinted PNG
# mask at app/assets/images/skins/scenes/<skin>-<id>.png is used when present (graceful fallback).
module Cosmetic::SceneCatalog
  module_function

  SCENES = {
    'arcade' => [
      { value: 'none',    name: 'None',          cost: 0 },
      { value: 'invader', name: 'Space Invader', tok: 'n1', cost: 250 },
      { value: 'sun',     name: 'Retro Sun',     tok: 'n3', cost: 300 },
      { value: 'cabinet', name: 'Cabinet',       tok: 'n2', req: 'Top the Arcade leaderboard' }
    ],
    'kawaii' => [
      { value: 'none',     name: 'None',        cost: 0 },
      { value: 'cat',      name: 'Loaf Cat',    tok: 'n1',   cost: 300 },
      { value: 'redpanda', name: 'Fuzzball',    tok: 'gold', cost: 350 },
      { value: 'stargirl', name: 'Star Jump',   tok: 'n2',   cost: 400 },
      { value: 'cloud',    name: 'Happy Cloud', tok: 'n2',   cost: 250 },
      { value: 'rainbow',  name: 'Rainbow',     tok: 'n1',   cost: 300 },
      { value: 'star',     name: 'Lucky Star',  tok: 'gold', req: 'Keep a 7-day streak' }
    ],
    'famicom' => [
      { value: 'none',       name: 'None',         cost: 0 },
      { value: 'controller', name: 'Controller',   tok: 'n1',   cost: 300 },
      { value: 'game',       name: 'World 1-1',    tok: 'n2',   cost: 350 },
      { value: 'switch',     name: 'Handheld',     tok: 'n3',   cost: 400 },
      { value: 'block',      name: '? Block',      tok: 'gold', cost: 250 },
      { value: 'pipe',       name: 'Warp Pipe',    tok: 'n3',   cost: 300 },
      { value: 'castle',     name: 'Pixel Castle', tok: 'n1',   req: 'Clear 50 questions' }
    ],
    'zen' => [
      { value: 'none',   name: 'None',         cost: 0 },
      { value: 'tree',   name: 'Blossom Tree', tok: 'n1', cost: 300 },
      { value: 'temple', name: 'Pagoda',       tok: 'n3', cost: 350 },
      { value: 'fuji',   name: 'Mt. Fuji',     tok: 'n2', cost: 300 },
      { value: 'bonsai', name: 'Bonsai',       tok: 'n3', cost: 350 }
    ],
    'pitch' => [
      { value: 'none',   name: 'None',        cost: 0 },
      { value: 'goal',   name: 'The Winner',  tok: 'n1', cost: 300 },
      { value: 'game',   name: 'Kick-off',    tok: 'n2', cost: 350 },
      { value: 'player', name: 'Number 7',    tok: 'n3', cost: 400 },
      { value: 'centre', name: 'Centre Spot', tok: 'n1', cost: 250 },
      { value: 'shirt',  name: 'Match Shirt', tok: 'n3', cost: 350 }
    ],
    'manga' => [
      { value: 'none',       name: 'None',        cost: 0 },
      { value: 'speedlines', name: 'Speed Lines', tok: 'n1', cost: 250 },
      { value: 'girl',       name: 'Heroine',     tok: 'n3', cost: 300 },
      { value: 'ninja',      name: 'Shinobi',     tok: 'n2', cost: 350 },
      { value: 'fight',      name: 'Clash',       tok: 'n1', req: 'Win 3 quizzes in a row' }
    ],
    'street' => [
      { value: 'none',      name: 'None',        cost: 0 },
      { value: 'throwup',   name: 'Throw-Up',    tok: 'n1',   cost: 250 },
      { value: 'paintdrip', name: 'Paint Drip',  tok: 'n2',   cost: 300 },
      { value: 'artist',    name: 'Writer',      tok: 'n3',   cost: 350 },
      { value: 'graffiti',  name: 'Chill Piece', tok: 'gold', req: 'Top the weekly leaderboard' }
    ]
  }.freeze

  # The per-skin shop category metadata (label/blurb), mirroring Cosmetic::Catalog's shape.
  CATEGORY = { en: 'Scene', jp: '背景', glyph: 'sparkle',
               blurb: 'A signature backdrop motif — appears behind every screen. Locked to this skin.' }.freeze

  def skins = SCENES.keys

  def scenes_for(skin) = SCENES[skin.to_s] || []

  def scene(skin, id) = scenes_for(skin).find { |s| s[:value] == id.to_s }

  # The token ('n1'|'n2'|'n3'|'gold') tinting a scene motif; falls back to n1.
  def token(skin, id) = scene(skin, id)&.fetch(:tok, 'n1') || 'n1'

  # The free default scene id for a skin (always 'none').
  def default_value(_skin) = 'none'
end
