# frozen_string_literal: true

# GlyphHelper — the skin glyph set as inline SVG (Plan 01, Phase 0).
#
# Ported from the prototype's <Icon> component
# (design/tenjin-design-system/project/flow/skins/sk-ui.jsx). These are line glyphs on a 24×24
# grid; stroke width adapts per skin (famicom is chunkier). They are NOT FontAwesome — FA5 stays
# for existing chrome; use these for skin surfaces (subject tiles, HUD, shop, avatars).
#
#   = glyph(:chip)
#   = glyph(:flame, size: 18, color: "var(--n1)")
#   = glyph(:torii, css_class: "tjs-icon--glow")
#
# Add the matching shop/avatar glyphs (sparkle, dice, crown, gem, sakura, heart) as the catalog
# grows — the prototype's full set is ported below.
module GlyphHelper
  # name => inner SVG markup. `%<c>s` is the colour for solid inner dots; the outer stroke is set
  # on the <svg>. Paths copied verbatim from sk-ui.jsx.
  GLYPHS = {
    chip: '<rect x="6" y="6" width="12" height="12" rx="1.5"/><path d="M9 9h6v6H9z"/><path d="M9 3v3M15 3v3M9 18v3M15 18v3M3 9h3M3 15h3M18 9h3M18 15h3"/>',
    scroll: '<path d="M7 4h10a2 2 0 0 1 2 2v11a3 3 0 0 1-3 3H6"/><path d="M5 4a2 2 0 0 0-2 2a2 2 0 0 0 2 2h2V6a2 2 0 0 0-2-2z"/><path d="M16 20a3 3 0 0 0 3-3"/><path d="M9 9h6M9 13h6"/>',
    globe: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.5 2.5 14 0 17M12 3.5c-2.5 2.5-2.5 14 0 17"/>',
    book: '<path d="M4 5a2 2 0 0 1 2-2h12v16H6a2 2 0 0 0-2 2z"/><path d="M4 19a2 2 0 0 1 2-2h12"/>',
    flame: '<path d="M12 3c1 3-2 4-2 7a4 4 0 0 0 8 0c0-1-.5-2-1-2.5C16 12 18 14 18 16a6 6 0 0 1-12 0c0-4 4-6 6-13z"/>',
    bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',
    star: '<path d="M12 3l2.5 5.5L20 9.5l-4 4 1 6-5-3-5 3 1-6-4-4 5.5-1z"/>',
    check: '<path d="M4 12l5 6L20 5"/>',
    x: '<path d="M6 6l12 12M18 6L6 18"/>',
    clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3.5 2"/>',
    home: '<path d="M4 11l8-7 8 7"/><path d="M6 9.5V20h12V9.5"/>',
    target: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.8" fill="%<c>s"/>',
    trophy: '<path d="M7 4h10v4a5 5 0 0 1-10 0z"/><path d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3M9 14h6M10 20h4M12 14v6"/>',
    list: '<path d="M8 6h12M8 12h12M8 18h12"/><circle cx="4" cy="6" r="1" fill="%<c>s" stroke="none"/><circle cx="4" cy="12" r="1" fill="%<c>s" stroke="none"/><circle cx="4" cy="18" r="1" fill="%<c>s" stroke="none"/>',
    chevron: '<path d="M9 6l6 6-6 6"/>',
    back: '<path d="M15 6l-6 6 6 6"/>',
    play: '<path d="M7 5l12 7-12 7z"/>',
    torii: '<path d="M3 6h18M4 8.5h16M6 6v13M18 6v13M9 9.5h6"/><path d="M3 6c2-1.5 16-1.5 18 0"/>',
    dice: '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="9" cy="9" r="1.2" fill="%<c>s" stroke="none"/><circle cx="15" cy="15" r="1.2" fill="%<c>s" stroke="none"/><circle cx="12" cy="12" r="1.2" fill="%<c>s" stroke="none"/>',
    tag: '<path d="M4 4h7l9 9-7 7-9-9z"/><circle cx="8.5" cy="8.5" r="1.4" fill="%<c>s" stroke="none"/>',
    sparkle: '<path d="M12 3c.6 4 2 5.4 6 6-4 .6-5.4 2-6 6-.6-4-2-5.4-6-6 4-.6 5.4-2 6-6z"/>',
    heart: '<path d="M12 20S4 15 4 9a4 4 0 0 1 8-1 4 4 0 0 1 8 1c0 6-8 11-8 11z"/>',
    sakura: '<path d="M12 12m-1.4 0a1.4 1.4 0 1 0 2.8 0 1.4 1.4 0 1 0-2.8 0"/><path d="M12 5.5c2.4 0 3.9 2 3.1 4.4M16.8 8.6c1.4 2 .8 4.4-1.6 5.5M14.5 16.8c-1 2.2-3.7 2.8-5.4 1M7.2 13.8c-2.4-1.1-3-3.5-1.6-5.5M9 9.9C8.2 7.5 9.7 5.5 12 5.5"/>',
    crown: '<path d="M4 8l3.5 3L12 5l4.5 6L20 8l-1.5 11h-13z"/><path d="M5.5 19h13"/>',
    gem: '<path d="M6 3h12l3 6-9 12L3 9z"/><path d="M3 9h18M9 3 7 9l5 12 5-12-2-6"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>'
  }.freeze

  def glyph(name, size: 24, color: 'currentColor', stroke_width: 1.8, css_class: nil)
    inner = GLYPHS[name.to_sym]
    return ''.html_safe if inner.nil?

    body = format(inner, c: color)
    classes = ['tjs-icon', css_class].compact.join(' ')
    <<~SVG.html_safe
      <svg class="#{classes}" width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="#{color}" stroke-width="#{stroke_width}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{body}</svg>
    SVG
  end
end
