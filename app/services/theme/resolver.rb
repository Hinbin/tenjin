# frozen_string_literal: true

# Resolver — turns a {skin, palette, dark} selection into the CSS-custom-property hash that
# the layout injects on <body style="…">. Direct port of `buildTheme()` from the prototype
# (design/tenjin-design-system/project/flow/skins/sk-data.jsx).
#
# This is the TOKEN layer only (colour + shape + font vars). The per-skin STRUCTURAL treatment
# that a single var can't express (glass blur, pixel offset shadow, sticker borders) lives in
# app/assets/stylesheets/skins/_structure.scss, keyed off the `data-skin` attribute.
#
# Storage-agnostic by design: callers pass a selection; how that selection is stored
# (Phase 0: localStorage/default; Phase 4: equipped ActiveCustomisation) is not this class's
# concern. See Theme::Selection.
#
#   Theme::Resolver.css_vars(skin: "arcade", palette: 0, dark: true)
#   # => { "--bg0" => "#0a0712", "--ink" => "#f3ecff", … }
#
#   Theme::Resolver.style_string(skin: "kawaii", palette: 1, dark: false)
#   # => "--bg0:#eef9ff;--bg1:#daf0ff;…"
module Theme::Resolver
  module_function

  # glow/accent intensity (prototype `--g`, 0..1). 0.6 matches the prototype default.
  DEFAULT_GLOW = 0.6

  def css_vars(skin: Theme::SkinCatalog::DEFAULT_SKIN, palette: Theme::SkinCatalog::DEFAULT_PALETTE,
               dark: Theme::SkinCatalog::DEFAULT_DARK, glow: DEFAULT_GLOW)
    meta = Theme::SkinCatalog.meta(skin)
    pal  = Theme::SkinCatalog.palette(skin, palette)
    p    = pal[dark ? :dark : :light]

    {
      '--bg0' => p[:bg0], '--bg1' => p[:bg1], '--grid' => p[:grid], '--surface' => p[:surface],
      '--line' => p[:line], '--ink' => p[:ink], '--dim' => p[:dim],
      '--n1' => p[:n1], '--n2' => p[:n2], '--n3' => p[:n3], '--gold' => p[:gold],
      '--edge' => p[:edge] || (dark ? '#000' : p[:ink]),
      '--track' => dark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.08)',
      # ideal text colour on an accent-filled button (prototype idealText fallback)
      '--on-accent' => dark ? '#0a0712' : '#ffffff',
      '--f-display' => meta[:fonts][:display], '--f-body' => meta[:fonts][:body], '--f-pixel' => meta[:fonts][:pixel],
      '--r-lg' => "#{meta[:r_lg]}px", '--r-md' => "#{meta[:r_md]}px", '--r-sm' => "#{meta[:r_sm]}px",
      '--btn-r' => "#{meta[:btn_r]}px", '--bd' => "#{meta[:bd]}px",
      '--g' => glow.to_s
    }
  end

  # Inline-style string for a <body style="…"> attribute (server-rendered → no theme flash).
  def style_string(**)
    css_vars(**).map { |k, v| "#{k}:#{v}" }.join(';')
  end
end
