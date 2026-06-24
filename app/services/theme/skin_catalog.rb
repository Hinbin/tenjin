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

  DEFAULT_SKIN = 'arcade'
  # Teachers/admins haven't got an equipped-skin flow yet, so their surfaces fall back to this
  # (calmer serif "zen" look) rather than the student default. See Theme::Selection#resolve_skin.
  DEFAULT_TEACHER_SKIN = 'zen'
  DEFAULT_PALETTE = 0 # index into PALETTES[skin]
  DEFAULT_DARK    = true

  # ── Structural DNA per skin ───────────────────────────────────────────────
  # fill:   'glass' (translucent + blur) | 'solid'
  # shadow: 'glow' (neon) | 'soft' (diffuse) | 'hard' (pixel offset) | 'none'
  META = {
    'arcade' => {
      label: 'Arcade', jp: 'アーケード',
      tagline: 'Neon glass and glowing edges — late-night Tokyo arcade energy.',
      fonts: { display: "'Zen Dots', system-ui, sans-serif", body: "'Zen Kaku Gothic New', system-ui, sans-serif", pixel: "'DotGothic16', monospace" },
      fill: 'glass', shadow: 'glow', bd: 1, r_lg: 22, r_md: 16, r_sm: 11, btn_r: 14,
      upper: true, d_space: '0.5px', glow_icons: true, blur: 8, d_weight: 400, body_weight: 400, head_size: 17,
      fx: { scanlines: true, grid: true, blobs: true, dots: false, dither: false }
    },
    'kawaii' => {
      label: 'Kawaii', jp: 'かわいい',
      tagline: 'Soft, rounded and pastel — bubbly type and sticker-pop shapes.',
      fonts: { display: "'Mochiy Pop One', system-ui, sans-serif", body: "'Zen Maru Gothic', system-ui, sans-serif", pixel: "'Yusei Magic', system-ui, sans-serif" },
      fill: 'solid', shadow: 'soft', bd: 2.5, r_lg: 30, r_md: 24, r_sm: 18, btn_r: 999,
      upper: false, d_space: '0px', glow_icons: false, blur: 0, sticker: true, d_weight: 400, body_weight: 500, head_size: 16,
      fx: { scanlines: false, grid: false, blobs: true, dots: true, dither: false }
    },
    'famicom' => {
      label: 'Famicom', jp: 'ファミコン',
      tagline: '8-bit pixels and hard-edged shadows — retro console throwback.',
      fonts: { display: "'Press Start 2P', system-ui, monospace", body: "'DotGothic16', monospace", pixel: "'Press Start 2P', monospace" },
      fill: 'solid', shadow: 'hard', bd: 3, r_lg: 0, r_md: 0, r_sm: 0, btn_r: 0,
      upper: true, d_space: '0px', glow_icons: false, blur: 0, pixel: true, sw: 2.4, d_weight: 400, body_weight: 400, head_size: 13,
      fx: { scanlines: true, grid: false, blobs: false, dots: false, dither: true }
    },
    # ── Zen ── serenity · cherry blossom · temple calm
    # Soft mincho serif, hairline borders, paper surfaces.
    'zen' => {
      label: 'Zen', jp: '禅',
      tagline: 'Serif calm on paper — quiet and refined.',
      fonts: { display: "'Zen Old Mincho', 'Shippori Mincho', serif", body: "'Zen Kaku Gothic New', system-ui, sans-serif", pixel: "'Shippori Mincho', serif" },
      fill: 'solid', shadow: 'soft', bd: 1, r_lg: 20, r_md: 15, r_sm: 11, btn_r: 999,
      upper: false, d_space: '0.04em', glow_icons: false, blur: 0, zen: true, serif: true,
      d_weight: 500, body_weight: 400, head_size: 19,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false }
    },
    # ── Matchday ── Premier-League pitch · floodlit turf · broadcast graphics
    # Condensed poster type (Anton), chalk-line cards, mowed-grass backdrop + centre circle.
    'pitch' => {
      label: 'Matchday', jp: '球技',
      tagline: 'Floodlit turf and broadcast graphics — condensed matchday energy.',
      fonts: { display: "'Anton', system-ui, sans-serif", body: "'Archivo', system-ui, sans-serif", pixel: "'Oswald', system-ui, sans-serif" },
      fill: 'solid', shadow: 'soft', bd: 1.5, r_lg: 12, r_md: 8, r_sm: 5, btn_r: 6,
      upper: true, d_space: '0.4px', glow_icons: false, blur: 0, ball_mark: true, broadcast: true,
      d_weight: 400, body_weight: 500, head_size: 18,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false, turf: true, pitch: true }
    },
    # ── Manga ── black-and-white ink · screentone · bold panels · speed lines
    # Heavy brush display type, thick ink borders with an offset, halftone dot wash.
    'manga' => {
      label: 'Manga', jp: '漫画',
      tagline: 'Inked panels and halftone screentone — bold black-and-white drama.',
      fonts: { display: "'Reggae One', system-ui, sans-serif", body: "'Zen Kaku Gothic New', system-ui, sans-serif", pixel: "'Yusei Magic', system-ui, sans-serif" },
      fill: 'solid', shadow: 'hard', bd: 2.5, r_lg: 6, r_md: 4, r_sm: 3, btn_r: 4,
      upper: true, d_space: '0px', glow_icons: false, blur: 0, sw: 2.2, manga: true,
      d_weight: 400, body_weight: 500, head_size: 19,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false, halftone: true }
    },
    # ── Street ── concrete grey · hi-vis spray paint · sticker-bomb energy
    # Bungee signage type, marker accents, thick black sticker outlines with an offset.
    'street' => {
      label: 'Street', jp: 'グラフィティ',
      tagline: 'Concrete grain and hi-vis spray paint — sticker-bomb street energy.',
      fonts: { display: "'Bungee', system-ui, sans-serif", body: "'Archivo', system-ui, sans-serif", pixel: "'Permanent Marker', cursive" },
      fill: 'solid', shadow: 'hard', bd: 2.5, r_lg: 14, r_md: 10, r_sm: 7, btn_r: 9,
      upper: true, d_space: '0.5px', glow_icons: false, blur: 0, sw: 2.6, street: true,
      d_weight: 400, body_weight: 600, head_size: 18,
      fx: { scanlines: false, grid: false, blobs: false, dots: false, dither: false, concrete: true }
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
    ],
    'pitch' => [
      { id: 'touchline', label: 'Touchline', jp: '芝',
        dark: { bg0: '#08200f', bg1: '#0c2a15', grid: '#114021', surface: '#0e2916', line: 'rgba(255,255,255,0.14)', ink: '#f1fbef', dim: '#8aab94', n1: '#c2f24d', n2: '#4db8ff', n3: '#ff6f91', gold: '#ffd23f' },
        light: { bg0: '#e9f6e1', bg1: '#dcefcf', grid: '#c4e4b2', surface: '#ffffff', line: '#d2e7c8', ink: '#12301a', dim: '#5d7f66', n1: '#3f9e1f', n2: '#0a86c4', n3: '#d6396a', gold: '#bb8800' } },
      { id: 'redArmy', label: 'Red Army', jp: '赤',
        dark: { bg0: '#0a200f', bg1: '#0d2a14', grid: '#114021', surface: '#0f2916', line: 'rgba(255,255,255,0.14)', ink: '#fbf0ef', dim: '#a89a94', n1: '#ff5252', n2: '#f2f2f2', n3: '#4db8ff', gold: '#ffd23f' },
        light: { bg0: '#e9f6e1', bg1: '#dcefcf', grid: '#c4e4b2', surface: '#ffffff', line: '#d2e7c8', ink: '#12301a', dim: '#5d7f66', n1: '#d62828', n2: '#3f7d52', n3: '#0a86c4', gold: '#bb8800' } },
      { id: 'skyBlue', label: 'Sky Blue', jp: '空',
        dark: { bg0: '#08200f', bg1: '#0c2a15', grid: '#114021', surface: '#0e2916', line: 'rgba(255,255,255,0.14)', ink: '#eef6fb', dim: '#8aaab2', n1: '#54c4ff', n2: '#eaf2ff', n3: '#b6f24a', gold: '#ffd23f' },
        light: { bg0: '#e9f6e1', bg1: '#dcefcf', grid: '#c4e4b2', surface: '#ffffff', line: '#d2e7c8', ink: '#12301a', dim: '#5d7f66', n1: '#0a86c4', n2: '#3f7d52', n3: '#3f9e1f', gold: '#bb8800' } },
      { id: 'trophyGold', label: 'Trophy', jp: '金',
        dark: { bg0: '#0a1c0f', bg1: '#0d2613', grid: '#123a1d', surface: '#102a16', line: 'rgba(255,255,255,0.14)', ink: '#fbf6e8', dim: '#a89f86', n1: '#ffd23f', n2: '#b6f24a', n3: '#4db8ff', gold: '#ffe27a' },
        light: { bg0: '#e9f6e1', bg1: '#dcefcf', grid: '#c4e4b2', surface: '#ffffff', line: '#d2e7c8', ink: '#12301a', dim: '#5d7f66', n1: '#a8801a', n2: '#3f9e1f', n3: '#0a86c4', gold: '#a8801a' } }
    ],
    'manga' => [
      { id: 'shonen', label: 'Shōnen', jp: '赤',
        dark: { bg0: '#131313', bg1: '#1b1b1b', grid: '#2f2f2f', surface: '#1e1e1e', line: 'rgba(255,255,255,0.16)', ink: '#f5f3ec', dim: '#9b988f', n1: '#ff2e2e', n2: '#f5f3ec', n3: '#c0bdb4', gold: '#ffce3a', edge: '#000000' },
        light: { bg0: '#f7f5ef', bg1: '#efece3', grid: '#d7d3c9', surface: '#ffffff', line: '#1a1713', ink: '#16130e', dim: '#746c61', n1: '#e21b1b', n2: '#16130e', n3: '#5d564d', gold: '#c08a00', edge: '#16130e' } },
      { id: 'aozora', label: 'Aozora', jp: '青',
        dark: { bg0: '#131313', bg1: '#1b1b1b', grid: '#2f2f2f', surface: '#1e1e1e', line: 'rgba(255,255,255,0.16)', ink: '#f5f3ec', dim: '#9b988f', n1: '#2f9bff', n2: '#f5f3ec', n3: '#bdc8d2', gold: '#ffce3a', edge: '#000000' },
        light: { bg0: '#f7f5ef', bg1: '#efece3', grid: '#d7d3c9', surface: '#ffffff', line: '#1a1713', ink: '#16130e', dim: '#746c61', n1: '#1a73d8', n2: '#16130e', n3: '#566270', gold: '#b07d18', edge: '#16130e' } },
      { id: 'murasaki', label: 'Murasaki', jp: '紫',
        dark: { bg0: '#131313', bg1: '#1b1b1b', grid: '#2f2f2f', surface: '#1e1e1e', line: 'rgba(255,255,255,0.16)', ink: '#f5f3ec', dim: '#9b988f', n1: '#b06bff', n2: '#f5f3ec', n3: '#c4bdd2', gold: '#ffce3a', edge: '#000000' },
        light: { bg0: '#f7f5ef', bg1: '#efece3', grid: '#d7d3c9', surface: '#ffffff', line: '#1a1713', ink: '#16130e', dim: '#746c61', n1: '#7d3ad0', n2: '#16130e', n3: '#5f5670', gold: '#b07d18', edge: '#16130e' } },
      { id: 'sumie', label: 'Sumi-e', jp: '墨',
        dark: { bg0: '#131313', bg1: '#1b1b1b', grid: '#2f2f2f', surface: '#1e1e1e', line: 'rgba(255,255,255,0.16)', ink: '#f5f3ec', dim: '#9b988f', n1: '#f5f3ec', n2: '#bdbab2', n3: '#8d8a82', gold: '#cfcabf', edge: '#000000' },
        light: { bg0: '#f7f5ef', bg1: '#efece3', grid: '#d7d3c9', surface: '#ffffff', line: '#1a1713', ink: '#16130e', dim: '#746c61', n1: '#16130e', n2: '#3a352e', n3: '#6d665b', gold: '#8a8276', edge: '#16130e' } }
    ],
    'street' => [
      { id: 'hivis', label: 'Hi-Vis', jp: '蛍光',
        dark: { bg0: '#1a1a1c', bg1: '#222225', grid: '#33333a', surface: '#212124', line: 'rgba(255,255,255,0.12)', ink: '#f1f1ee', dim: '#9a9a94', n1: '#caff33', n2: '#ff5ea8', n3: '#39d0ff', gold: '#ffc63a', edge: '#000000' },
        light: { bg0: '#e9e8e4', bg1: '#dedcd6', grid: '#c7c4bc', surface: '#f6f5f1', line: '#1c1c1a', ink: '#1a1a18', dim: '#6c6a63', n1: '#7fae00', n2: '#e0307f', n3: '#0a93c4', gold: '#b87f18', edge: '#1a1a18' } },
      { id: 'hazard', label: 'Hazard', jp: '危険',
        dark: { bg0: '#1a1a1c', bg1: '#222225', grid: '#33333a', surface: '#212124', line: 'rgba(255,255,255,0.12)', ink: '#f1f1ee', dim: '#9a9a94', n1: '#ff7a18', n2: '#ffd23a', n3: '#f1f1ee', gold: '#ffc63a', edge: '#000000' },
        light: { bg0: '#e9e8e4', bg1: '#dedcd6', grid: '#c7c4bc', surface: '#f6f5f1', line: '#1c1c1a', ink: '#1a1a18', dim: '#6c6a63', n1: '#e0631a', n2: '#c79200', n3: '#1a1a18', gold: '#b87f18', edge: '#1a1a18' } },
      { id: 'bubblegum', label: 'Bubblegum', jp: '桃',
        dark: { bg0: '#1a1a1c', bg1: '#222225', grid: '#33333a', surface: '#212124', line: 'rgba(255,255,255,0.12)', ink: '#f1f1ee', dim: '#9a9a94', n1: '#ff5ea8', n2: '#39e0d0', n3: '#caff33', gold: '#ffc63a', edge: '#000000' },
        light: { bg0: '#e9e8e4', bg1: '#dedcd6', grid: '#c7c4bc', surface: '#f6f5f1', line: '#1c1c1a', ink: '#1a1a18', dim: '#6c6a63', n1: '#e0307f', n2: '#0a9e90', n3: '#7fae00', gold: '#b87f18', edge: '#1a1a18' } },
      { id: 'blackbook', label: 'Blackbook', jp: '黒',
        dark: { bg0: '#101012', bg1: '#161618', grid: '#2a2a30', surface: '#19191c', line: 'rgba(255,255,255,0.12)', ink: '#f1f1ee', dim: '#8a8a92', n1: '#3a7bff', n2: '#f1f1ee', n3: '#8a8a92', gold: '#ffc63a', edge: '#000000' },
        light: { bg0: '#e4e3df', bg1: '#d7d6d0', grid: '#bdbab2', surface: '#f3f2ee', line: '#19191a', ink: '#161618', dim: '#5a5a60', n1: '#2155d8', n2: '#161618', n3: '#5a5a60', gold: '#b87f18', edge: '#161618' } }
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
