# frozen_string_literal: true

# SkinCatalog — the single source of truth for the reskinnable theme system.
#
# Ported verbatim from the design prototype:
#   design/tenjin-design-system/project/flow/skins/sk-data.jsx  (the `SKINS` object)
#
# Two-level theming:  SKIN (look & feel)  ×  PALETTE (colour)  ×  dark|light.
#
# `META[skin]`     — structural DNA (fonts, radii, border width, shadow style, fx flags).
# `PALETTES[skin]` — ordered list of palettes; index 0 is the FREE base palette (decision #2),
#                    each with a `:dark` and `:light` colour map.
#
# Theme::Resolver turns a {skin, palette, dark} selection into the CSS-custom-property hash
# the layout injects on <body>. The per-skin *structural* CSS (glass blur, pixel offset
# shadow, sticker borders) lives in app/assets/stylesheets/skins/_structure.scss — colour and
# shape tokens here; treatment there.
#
# NOTE FOR EXECUTORS: this data is complete and verified against the prototype. Do not
# hand-retype it — extend it (a 5th skin, more palettes) by appending, and add the matching
# [data-skin=…] block in _structure.scss.
module Theme::SkinCatalog
  module_function

  DEFAULT_SKIN    = 'arcade'
  DEFAULT_PALETTE = 0 # index into PALETTES[skin]
  DEFAULT_DARK    = true

  # ── Structural DNA per skin ───────────────────────────────────────────────
  # fill:   'glass' (translucent + blur) | 'solid'
  # shadow: 'glow' (neon) | 'soft' (diffuse) | 'hard' (pixel offset) | 'none'
  META = {
    'arcade' => {
      label: 'Arcade', jp: 'アーケード',
      fonts: { display: "'Zen Dots', system-ui, sans-serif", body: "'Zen Kaku Gothic New', system-ui, sans-serif", pixel: "'DotGothic16', monospace" },
      fill: 'glass', shadow: 'glow', bd: 1, r_lg: 22, r_md: 16, r_sm: 11, btn_r: 14,
      upper: true, d_space: '0.5px', glow_icons: true, blur: 8, d_weight: 400, body_weight: 400, head_size: 17,
      fx: { scanlines: true, grid: true, blobs: true, dots: false, dither: false }
    },
    'kawaii' => {
      label: 'Kawaii', jp: 'かわいい',
      fonts: { display: "'Mochiy Pop One', system-ui, sans-serif", body: "'Zen Maru Gothic', system-ui, sans-serif", pixel: "'Yusei Magic', system-ui, sans-serif" },
      fill: 'solid', shadow: 'soft', bd: 2.5, r_lg: 30, r_md: 24, r_sm: 18, btn_r: 999,
      upper: false, d_space: '0px', glow_icons: false, blur: 0, sticker: true, d_weight: 400, body_weight: 500, head_size: 16,
      fx: { scanlines: false, grid: false, blobs: true, dots: true, dither: false }
    },
    'minimal' => {
      label: 'Minimal', jp: 'ミニマル',
      fonts: { display: "'Space Grotesk', system-ui, sans-serif", body: "'Plus Jakarta Sans', system-ui, sans-serif", pixel: "'Space Grotesk', system-ui, sans-serif" },
      fill: 'solid', shadow: 'soft', bd: 1, r_lg: 18, r_md: 14, r_sm: 10, btn_r: 11,
      upper: false, d_space: '-0.01em', glow_icons: false, blur: 0, flat_shadow: true, d_weight: 600, body_weight: 500, head_size: 18,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false }
    },
    'famicom' => {
      label: 'Famicom', jp: 'ファミコン',
      fonts: { display: "'Press Start 2P', system-ui, monospace", body: "'DotGothic16', monospace", pixel: "'Press Start 2P', monospace" },
      fill: 'solid', shadow: 'hard', bd: 3, r_lg: 0, r_md: 0, r_sm: 0, btn_r: 0,
      upper: true, d_space: '0px', glow_icons: false, blur: 0, pixel: true, sw: 2.4, d_weight: 400, body_weight: 400, head_size: 13,
      fx: { scanlines: true, grid: false, blobs: false, dots: false, dither: true }
    },
    # ── Zen ── serenity · cherry blossom · temple calm
    # Soft mincho serif, hairline borders, paper surfaces, drifting petals.
    'zen' => {
      label: 'Zen', jp: '禅',
      fonts: { display: "'Zen Old Mincho', 'Shippori Mincho', serif", body: "'Zen Kaku Gothic New', system-ui, sans-serif", pixel: "'Shippori Mincho', serif" },
      fill: 'solid', shadow: 'soft', bd: 1, r_lg: 20, r_md: 15, r_sm: 11, btn_r: 999,
      upper: false, d_space: '0.04em', glow_icons: false, blur: 0, zen: true, serif: true,
      d_weight: 500, body_weight: 400, head_size: 19,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false, petals: true }
    }
  }.freeze

  # ── Palettes per skin (index 0 = free base palette) ───────────────────────
  PALETTES = {
    'arcade' => [
      { id: 'neonTokyo', label: 'Neon Tokyo', jp: '東京',
        dark: { bg0: '#0a0712', bg1: '#170c26', grid: '#3a1f5c', surface: 'rgba(28,18,46,0.72)', line: 'rgba(255,255,255,0.10)', ink: '#f3ecff', dim: '#9d90b8', n1: '#ff2d95', n2: '#27e6e6', n3: '#b14dff', gold: '#ffd23f' },
        light: { bg0: '#f6f0e8', bg1: '#efe6da', grid: '#e3b9cf', surface: 'rgba(255,255,255,0.82)', line: 'rgba(40,20,50,0.12)', ink: '#241332', dim: '#7a6a86', n1: '#e01277', n2: '#0a9ba6', n3: '#7d2bd6', gold: '#c98a00' } },
      { id: 'sunsetShowa', label: 'Sunset Shōwa', jp: '昭和',
        dark: { bg0: '#160810', bg1: '#2a130f', grid: '#5c2a1f', surface: 'rgba(46,22,20,0.72)', line: 'rgba(255,255,255,0.10)', ink: '#ffeee2', dim: '#b89888', n1: '#ff6b9d', n2: '#ff8a3d', n3: '#ffc15e', gold: '#ffd23f' },
        light: { bg0: '#fbf0e4', bg1: '#f6e3d2', grid: '#edc3a3', surface: 'rgba(255,255,255,0.84)', line: 'rgba(60,30,20,0.12)', ink: '#3a1c12', dim: '#8a6a58', n1: '#e0356f', n2: '#d8631a', n3: '#bd7400', gold: '#c98a00' } },
      { id: 'vaporMist', label: 'Vapor Mist', jp: '蒸気',
        dark: { bg0: '#0b0a1c', bg1: '#161033', grid: '#2f2a66', surface: 'rgba(24,20,52,0.72)', line: 'rgba(255,255,255,0.10)', ink: '#eef0ff', dim: '#9090c0', n1: '#9d6bff', n2: '#27e6e6', n3: '#ff6bd6', gold: '#ffe06b' },
        light: { bg0: '#f0eefb', bg1: '#e6e2f6', grid: '#c7c0ee', surface: 'rgba(255,255,255,0.85)', line: 'rgba(30,20,60,0.12)', ink: '#1d1640', dim: '#6e6a96', n1: '#6a37d6', n2: '#0a9ba6', n3: '#c233a0', gold: '#b88a00' } },
      { id: 'matchaCRT', label: 'Matcha CRT', jp: '抹茶',
        dark: { bg0: '#06120c', bg1: '#0c2418', grid: '#1f5c3a', surface: 'rgba(14,38,26,0.72)', line: 'rgba(255,255,255,0.10)', ink: '#e8fff0', dim: '#86b89c', n1: '#39ff9e', n2: '#ffd23f', n3: '#45e6c4', gold: '#ffd23f' },
        light: { bg0: '#eef6ec', bg1: '#e2efdf', grid: '#bfe0c2', surface: 'rgba(255,255,255,0.86)', line: 'rgba(20,50,30,0.12)', ink: '#0f2a1c', dim: '#5e8068', n1: '#0f9e58', n2: '#b88a00', n3: '#0a9b86', gold: '#b88a00' } }
    ],
    'kawaii' => [
      { id: 'strawberry', label: 'Strawberry', jp: '苺',
        dark: { bg0: '#241024', bg1: '#37173a', grid: '#5a2a5a', surface: '#3a1d3e', line: 'rgba(255,182,221,0.22)', ink: '#ffe9f5', dim: '#d6a8c6', n1: '#ff8fc6', n2: '#7cc8ff', n3: '#ffd36b', gold: '#ffd36b', edge: '#1c0c1e' },
        light: { bg0: '#fff2f8', bg1: '#ffe3f0', grid: '#ffc8e2', surface: '#ffffff', line: '#ffd0e6', ink: '#7a3a64', dim: '#c089a6', n1: '#ff77b6', n2: '#5cb8f7', n3: '#ffc24d', gold: '#ffb03a', edge: '#ffc0db' } },
      { id: 'soda', label: 'Soda Pop', jp: '蘇打',
        dark: { bg0: '#0e1f2e', bg1: '#143046', grid: '#1f4a66', surface: '#173a52', line: 'rgba(150,210,255,0.22)', ink: '#e6f6ff', dim: '#9bc4dc', n1: '#62c8ff', n2: '#ff9ed6', n3: '#8ce6b4', gold: '#ffd86b', edge: '#08151f' },
        light: { bg0: '#eef9ff', bg1: '#daf0ff', grid: '#bfe6ff', surface: '#ffffff', line: '#c4e7fb', ink: '#2f5d77', dim: '#84afc4', n1: '#3eb6f6', n2: '#ff8fcb', n3: '#5fd49a', gold: '#ffbb3d', edge: '#c4e7fb' } },
      { id: 'matchaMochi', label: 'Matcha Mochi', jp: '抹茶',
        dark: { bg0: '#11251a', bg1: '#1a3a28', grid: '#2c5a3e', surface: '#1f4630', line: 'rgba(170,230,190,0.22)', ink: '#e9fbef', dim: '#9fcbb0', n1: '#7ad9a6', n2: '#ffd574', n3: '#ff9ec4', gold: '#ffd574', edge: '#0b1810' },
        light: { bg0: '#f1faf0', bg1: '#e2f3e2', grid: '#c6e7c6', surface: '#ffffff', line: '#cdeacd', ink: '#3c6b4c', dim: '#92b89e', n1: '#5cc78c', n2: '#ffc24d', n3: '#ff8fbf', gold: '#ffb03a', edge: '#cdeacd' } },
      { id: 'lavender', label: 'Lavender', jp: '藤',
        dark: { bg0: '#1d1633', bg1: '#2c2150', grid: '#473a78', surface: '#322652', line: 'rgba(190,176,255,0.22)', ink: '#efeaff', dim: '#b4a8d6', n1: '#b69bff', n2: '#8fd9ff', n3: '#ffb3d8', gold: '#ffe07a', edge: '#120d22' },
        light: { bg0: '#f5f1ff', bg1: '#ece3ff', grid: '#d8c8f7', surface: '#ffffff', line: '#ddd0f7', ink: '#574a78', dim: '#a99ec4', n1: '#a98bf0', n2: '#5cc1f7', n3: '#ff8fc4', gold: '#ffbb3d', edge: '#ddd0f7' } }
    ],
    'minimal' => [
      { id: 'indigo', label: 'Indigo', jp: '藍',
        dark: { bg0: '#0e1016', bg1: '#13161f', grid: '#222838', surface: '#171a23', line: 'rgba(255,255,255,0.09)', ink: '#f1f3f8', dim: '#8b91a3', n1: '#7c83ff', n2: '#38bdf8', n3: '#a78bfa', gold: '#f0b454' },
        light: { bg0: '#f7f8fb', bg1: '#eef1f6', grid: '#dfe4ed', surface: '#ffffff', line: '#e7eaf1', ink: '#171a22', dim: '#6b7180', n1: '#4f46e5', n2: '#0284c7', n3: '#7c3aed', gold: '#b9791a' } },
      { id: 'emerald', label: 'Emerald', jp: '翠',
        dark: { bg0: '#0b1110', bg1: '#0f1816', grid: '#1d2c28', surface: '#121c1a', line: 'rgba(255,255,255,0.09)', ink: '#eef5f2', dim: '#869a93', n1: '#34d399', n2: '#22b8cf', n3: '#5eead4', gold: '#ecc561' },
        light: { bg0: '#f5faf8', bg1: '#eaf4f0', grid: '#d6e8e1', surface: '#ffffff', line: '#e0ece7', ink: '#13211c', dim: '#5f7a70', n1: '#059669', n2: '#0e8aa8', n3: '#0d9488', gold: '#a47d18' } },
      { id: 'cobalt', label: 'Cobalt', jp: '紺',
        dark: { bg0: '#0c1018', bg1: '#101521', grid: '#1f2740', surface: '#141a26', line: 'rgba(255,255,255,0.09)', ink: '#eef2f8', dim: '#838eaa', n1: '#4d8dff', n2: '#2dd4bf', n3: '#818cf8', gold: '#e6b85c' },
        light: { bg0: '#f6f8fc', bg1: '#eaf0f8', grid: '#d9e3f0', surface: '#ffffff', line: '#e3eaf3', ink: '#141a26', dim: '#677085', n1: '#2563eb', n2: '#0d9488', n3: '#5457e6', gold: '#b07d18' } },
      { id: 'clay', label: 'Clay', jp: '土',
        dark: { bg0: '#15110e', bg1: '#1c1611', grid: '#332a20', surface: '#201a14', line: 'rgba(255,255,255,0.09)', ink: '#f5efe8', dim: '#a39586', n1: '#f08a4b', n2: '#3db8b0', n3: '#e0a36a', gold: '#e6c061' },
        light: { bg0: '#faf7f3', bg1: '#f2ece4', grid: '#e6dccf', surface: '#ffffff', line: '#ece4d9', ink: '#241c14', dim: '#847766', n1: '#e0651a', n2: '#0e8a82', n3: '#b06a2a', gold: '#a8821c' } }
    ],
    'famicom' => [
      { id: 'famicomRed', label: 'Famicom', jp: '赤',
        dark: { bg0: '#161013', bg1: '#211519', grid: '#3a2530', surface: '#241a1e', line: '#3f2e34', ink: '#fdeede', dim: '#b59a8e', n1: '#e8413c', n2: '#3aa0e0', n3: '#f4b63a', gold: '#f4d23a', edge: '#0a0608' },
        light: { bg0: '#f3e9d6', bg1: '#ecdcc2', grid: '#d8c29a', surface: '#fff8ea', line: '#2a1a12', ink: '#2a1a12', dim: '#7a6450', n1: '#d6322d', n2: '#1f7fc4', n3: '#d68a00', gold: '#c99700', edge: '#2a1a12' } },
      { id: 'gameBoy', label: 'Game Boy', jp: '緑',
        dark: { bg0: '#0b1a0b', bg1: '#0f2810', grid: '#1f4a1f', surface: '#13330f', line: '#2c5a1f', ink: '#cde86b', dim: '#7a9a4a', n1: '#9bbc0f', n2: '#8bac0f', n3: '#cde86b', gold: '#e0f080', edge: '#06120a' },
        light: { bg0: '#cadc9f', bg1: '#bcd08f', grid: '#9bbc0f', surface: '#dcecb4', line: '#0f380f', ink: '#0f380f', dim: '#42662a', n1: '#306230', n2: '#0f380f', n3: '#557a1a', gold: '#3a5a0f', edge: '#0f380f' } },
      { id: 'arcadePurple', label: 'Arcade', jp: '紫',
        dark: { bg0: '#15082a', bg1: '#1f0d3c', grid: '#3a1f66', surface: '#260f44', line: '#43236e', ink: '#f3e6ff', dim: '#a98ec8', n1: '#b14dff', n2: '#ff2e88', n3: '#00e5ff', gold: '#ffd400', edge: '#0a0418' },
        light: { bg0: '#ece2fb', bg1: '#e0d0f7', grid: '#c4a8ee', surface: '#f6efff', line: '#2a1048', ink: '#2a1048', dim: '#6e5a8a', n1: '#7b2ff7', n2: '#d6188a', n3: '#0a96c4', gold: '#c99700', edge: '#2a1048' } },
      { id: 'superBlue', label: 'Super', jp: '青',
        dark: { bg0: '#0a0f24', bg1: '#0f1838', grid: '#1f2f66', surface: '#13204a', line: '#26386e', ink: '#e6ecff', dim: '#8e9ac8', n1: '#3a6cff', n2: '#ff3a3a', n3: '#2ad24a', gold: '#fcfc3a', edge: '#050818' },
        light: { bg0: '#dfe4f5', bg1: '#cdd6ee', grid: '#a8b6e0', surface: '#eef1fb', line: '#10184a', ink: '#10184a', dim: '#5a6488', n1: '#2038c4', n2: '#d61f1f', n3: '#0f9e2a', gold: '#bba800', edge: '#10184a' } }
    ],
    'zen' => [
      { id: 'sakura', label: 'Sakura', jp: '桜',
        dark: { bg0: '#191216', bg1: '#231a20', grid: '#3b2b34', surface: '#241b21', line: 'rgba(255,236,242,0.09)', ink: '#f6ecf0', dim: '#b39ca6', n1: '#f0a8c0', n2: '#9ec4b6', n3: '#c9a8d8', gold: '#e6c690' },
        light: { bg0: '#faf4f5', bg1: '#f3e8ec', grid: '#ecd6dd', surface: '#ffffff', line: '#efdfe4', ink: '#3a2a31', dim: '#8c7680', n1: '#d2829e', n2: '#5f9685', n3: '#a07cb6', gold: '#b58f4a' } },
      { id: 'niwa', label: 'Moss Garden', jp: '庭',
        dark: { bg0: '#10160f', bg1: '#172017', grid: '#2a3a28', surface: '#1a221a', line: 'rgba(236,243,233,0.09)', ink: '#eef3e9', dim: '#9eae97', n1: '#a8c98f', n2: '#e8b4c0', n3: '#88c4b6', gold: '#e0c489' },
        light: { bg0: '#f3f6ef', bg1: '#e8efe2', grid: '#d6e2cd', surface: '#ffffff', line: '#e1ebd9', ink: '#2c3527', dim: '#7c8a74', n1: '#6e9650', n2: '#c4849a', n3: '#52917f', gold: '#a98a46' } },
      { id: 'sumi', label: 'Ink Wash', jp: '墨',
        dark: { bg0: '#121418', bg1: '#181b21', grid: '#2a2f38', surface: '#1b1f26', line: 'rgba(238,240,244,0.09)', ink: '#eef0f4', dim: '#9aa0ad', n1: '#8fa8c4', n2: '#c4b0a0', n3: '#a6b2c8', gold: '#d6be88' },
        light: { bg0: '#f4f5f7', bg1: '#eaecf0', grid: '#dadde4', surface: '#ffffff', line: '#e6e8ee', ink: '#2a2e36', dim: '#7c828f', n1: '#577699', n2: '#90806e', n3: '#66748a', gold: '#a08749' } },
      { id: 'tasogare', label: 'Temple Dusk', jp: '黄昏',
        dark: { bg0: '#141220', bg1: '#1c1830', grid: '#322b4e', surface: '#1f1b30', line: 'rgba(240,236,248,0.09)', ink: '#f0ecf8', dim: '#a89cc0', n1: '#b8a0e0', n2: '#f0b0a6', n3: '#8eaee0', gold: '#e6c690' },
        light: { bg0: '#f6f3fb', bg1: '#ece5f5', grid: '#dcd2ee', surface: '#ffffff', line: '#e6def2', ink: '#322a44', dim: '#867c9a', n1: '#8a6cbe', n2: '#cf8276', n3: '#5a7eba', gold: '#a98a4a' } }
    ]
  }.freeze

  def skin_ids = META.keys

  def skin?(id) = META.key?(id.to_s)

  def meta(skin) = META[skin.to_s] || META[DEFAULT_SKIN]

  def palettes(skin) = PALETTES[skin.to_s] || PALETTES[DEFAULT_SKIN]

  # Clamp a palette index into range for the given skin.
  def palette(skin, index)
    list = palettes(skin)
    list[index.to_i.clamp(0, list.length - 1)]
  end

  # The free base palette id for a skin (decision #2: index 0 is free).
  def base_palette_id(skin) = palettes(skin).first[:id]
end
