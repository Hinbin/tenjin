# frozen_string_literal: true

# SceneArtHelper — inline-SVG artwork for the skin-locked Scenes (Plan 01, scenes phase).
# Paths ported verbatim from `SceneArt` in
#   design/tenjin-design-system/project/flow/skins/sk-cosmetics.jsx
#
# Not every scene has SVG art: the prototype draws ~15 from primitive shapes and ships the rest as
# black-on-transparent PNGs re-tinted with the scene token. Mirror that here — `scene_layer` renders
# a tinted PNG mask when app/assets/images/skins/scenes/<skin>-<id>.png exists, otherwise the inline
# SVG below (ART), otherwise nothing. The token colour (`var(--n1)` …) tints either form; `%<c>s`
# marks where it is interpolated and `var(--bg0)` is negative space (cut-outs).
module SceneArtHelper
  # 8×11 bitmap for the arcade Space Invader (drawn procedurally like the prototype).
  INVADER = %w[
    00100000100 00010001000 00111111100 01101110110
    11111111111 10111111101 10100000101 00011011000
  ].freeze

  # id => SVG inner markup template (%<c>s = token colour). Procedural scenes (invader) are built
  # in code below; PNG-only scenes (cat, controller, girl, throwup, …) deliberately have no entry.
  ART = {
    'sun' => '<defs><clipPath id="sunc"><circle cx="50" cy="52" r="34"/></clipPath></defs><circle cx="50" cy="52" r="34" fill="%<c>s" opacity="0.9"/><g clip-path="url(#sunc)"><rect x="14" y="60" width="72" height="2" fill="var(--bg0)"/><rect x="14" y="67" width="72" height="3.6" fill="var(--bg0)"/><rect x="14" y="75" width="72" height="5.2" fill="var(--bg0)"/><rect x="14" y="84" width="72" height="6.8" fill="var(--bg0)"/><rect x="14" y="94" width="72" height="8.4" fill="var(--bg0)"/></g>',
    'cabinet' => '<g fill="none" stroke="%<c>s" stroke-width="2.4" stroke-linejoin="round"><rect x="30" y="14" width="40" height="72" rx="4"/><rect x="36" y="22" width="28" height="20" rx="2" fill="%<c>s" opacity="0.4" stroke="none"/><line x1="36" y1="50" x2="64" y2="50"/><circle cx="44" cy="60" r="3" fill="%<c>s" stroke="none"/><circle cx="56" cy="60" r="3" fill="%<c>s" stroke="none"/></g>',
    'cloud' => '<g fill="%<c>s"><ellipse cx="50" cy="56" rx="34" ry="20"/><circle cx="34" cy="50" r="15"/><circle cx="64" cy="48" r="17"/><circle cx="50" cy="42" r="16"/><circle cx="42" cy="52" r="2.4" fill="var(--bg0)"/><circle cx="60" cy="52" r="2.4" fill="var(--bg0)"/><path d="M44 60 q6 5 12 0" fill="none" stroke="var(--bg0)" stroke-width="2" stroke-linecap="round"/></g>',
    'rainbow' => '<path d="M14 64 A36 36 0 0 1 86 64" fill="none" stroke="%<c>s" stroke-width="6" stroke-linecap="round" opacity="1"/><path d="M22 64 A28 28 0 0 1 78 64" fill="none" stroke="%<c>s" stroke-width="6" stroke-linecap="round" opacity="0.7"/><path d="M30 64 A20 20 0 0 1 70 64" fill="none" stroke="%<c>s" stroke-width="6" stroke-linecap="round" opacity="0.45"/>',
    'star' => '<svg x="4" y="4" width="92" height="92" viewBox="0 0 24 24" fill="none" stroke="%<c>s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3c.6 4 2 5.4 6 6-4 .6-5.4 2-6 6-.6-4-2-5.4-6-6 4-.6 5.4-2 6-6z"/></svg>',
    'block' => '<g><rect x="26" y="26" width="48" height="48" fill="%<c>s"/><rect x="26" y="26" width="48" height="48" fill="none" stroke="var(--bg0)" stroke-width="3"/><rect x="30" y="30" width="4" height="4" fill="var(--bg0)"/><rect x="66" y="30" width="4" height="4" fill="var(--bg0)"/><rect x="30" y="66" width="4" height="4" fill="var(--bg0)"/><rect x="66" y="66" width="4" height="4" fill="var(--bg0)"/><text x="50" y="62" text-anchor="middle" font-family="var(--f-pixel)" font-size="34" fill="var(--bg0)" font-weight="700">?</text></g>',
    'pipe' => '<g fill="%<c>s"><rect x="28" y="38" width="44" height="48"/><rect x="22" y="28" width="56" height="14"/><rect x="33" y="44" width="6" height="40" fill="var(--bg0)" opacity="0.35"/></g>',
    'castle' => '<g fill="%<c>s"><rect x="28" y="28" width="8" height="10"/><rect x="40" y="28" width="8" height="10"/><rect x="52" y="28" width="8" height="10"/><rect x="64" y="28" width="8" height="10"/><rect x="28" y="38" width="44" height="40"/><rect x="44" y="56" width="12" height="22" fill="var(--bg0)"/><rect x="44" y="56" width="12" height="6" fill="var(--bg0)"/></g>',
    'tree' => '<g><rect x="47" y="58" width="6" height="28" fill="%<c>s" opacity="0.8"/><path d="M50 60 q-12 0 -16 -8 M50 60 q12 0 16 -8" fill="none" stroke="%<c>s" stroke-width="2.5" opacity="0.7"/><circle cx="50" cy="34" r="18" fill="%<c>s" opacity="0.75"/><circle cx="34" cy="44" r="12" fill="%<c>s" opacity="0.75"/><circle cx="66" cy="44" r="12" fill="%<c>s" opacity="0.75"/><circle cx="40" cy="28" r="10" fill="%<c>s" opacity="0.75"/><circle cx="60" cy="28" r="10" fill="%<c>s" opacity="0.75"/></g>',
    'temple' => '<g fill="%<c>s"><polygon points="20 48, 80 48, 72 30, 28 30" opacity="0.85"/><polygon points="26 60, 74 60, 66 46, 34 46" opacity="0.85"/><polygon points="32 72, 68 72, 60 62, 40 62" opacity="0.85"/><rect x="40" y="72" width="20" height="14"/><rect x="44" y="76" width="12" height="10" fill="var(--bg0)"/></g>',
    'fuji' => '<g><polygon points="50 26, 80 78, 20 78" fill="%<c>s" opacity="0.8"/><polygon points="50 26, 60 43, 54 40, 50 46, 46 40, 40 43" fill="var(--bg0)" opacity="0.9"/></g>',
    'centre' => '<g fill="none" stroke="%<c>s" stroke-width="2.4"><line x1="6" y1="50" x2="94" y2="50"/><circle cx="50" cy="50" r="28"/><circle cx="50" cy="50" r="3.4" fill="%<c>s" stroke="none"/></g>',
    'goal' => '<g stroke="%<c>s" fill="none" stroke-width="2.6"><rect x="22" y="26" width="56" height="44"/><line x1="34" y1="30" x2="34" y2="70" stroke-width="1.2" opacity="0.6"/><line x1="46" y1="30" x2="46" y2="70" stroke-width="1.2" opacity="0.6"/><line x1="58" y1="30" x2="58" y2="70" stroke-width="1.2" opacity="0.6"/><line x1="26" y1="40" x2="74" y2="40" stroke-width="1.2" opacity="0.6"/><line x1="26" y1="52" x2="74" y2="52" stroke-width="1.2" opacity="0.6"/><line x1="26" y1="64" x2="74" y2="64" stroke-width="1.2" opacity="0.6"/><line x1="14" y1="78" x2="86" y2="78" stroke-width="3"/></g>',
    'shirt' => '<g><path d="M38 24 L30 30 L22 44 L31 50 L34 46 L34 82 L66 82 L66 46 L69 50 L78 44 L70 30 L62 24 Q50 34 38 24 Z" fill="%<c>s" opacity="0.82"/><text x="50" y="70" text-anchor="middle" font-family="var(--f-display)" font-size="26" fill="var(--bg0)">10</text></g>'
  }.freeze

  # Render the full scene backdrop layer for an equipped scene, or nil when there is no art.
  #   skin  : active skin id           id: scene id ('tree' …; 'none' / blank → nil)
  #   color : token CSS value (e.g. 'var(--n1)')
  def scene_layer(skin, id, color)
    return nil if id.blank? || id == 'none'

    scene_png?(skin, id) ? tinted_png_mask(skin, id, color) : scene_art_svg(id, color)
  end

  # The inline SVG (html_safe) for a scene id, or nil when only a PNG can render it.
  def scene_art_svg(id, color)
    inner = id == 'invader' ? invader_rects(color) : (ART[id] && format(ART[id], c: color))
    return nil if inner.nil?

    %(<svg viewBox="0 0 100 100" width="100%" height="100%" style="overflow:visible">#{inner}</svg>).html_safe
  end

  private

  # True when a tinted-PNG asset has been dropped in for this scene.
  def scene_png?(skin, id)
    path = Rails.root.join("app/assets/images/skins/scenes/#{skin}-#{id}.png")
    (@scene_png_cache ||= {}).fetch([skin, id]) { @scene_png_cache[[skin, id]] = path.exist? }
  end

  # A div whose background is the scene token, masked by the black-on-transparent PNG — so the
  # artwork inherits the palette/dark-mode/glow exactly like the SVG does.
  def tinted_png_mask(skin, id, color)
    src = image_path("skins/scenes/#{skin}-#{id}.png")
    style = "width:100%;height:100%;background-color:#{color};" \
            "-webkit-mask:url(#{src}) no-repeat center/contain;mask:url(#{src}) no-repeat center/contain;"
    tag.div('', style: style)
  end

  def invader_rects(color)
    unit = 7
    ox = (100 - (INVADER.first.length * unit)) / 2.0
    oy = (100 - (INVADER.length * unit)) / 2.0
    rects = invader_cells.map { |gx, gy| invader_rect(ox + (gx * unit), oy + (gy * unit), color) }
    "<g>#{rects.join}</g>"
  end

  # [x, y] grid coordinates of every lit pixel in the bitmap.
  def invader_cells
    INVADER.each_with_index.flat_map do |row, gy|
      (0...row.length).select { |gx| row[gx] == '1' }.map { |gx| [gx, gy] }
    end
  end

  def invader_rect(left, top, color)
    %(<rect x="#{left}" y="#{top}" width="7.6" height="7.6" fill="#{color}"/>)
  end
end
