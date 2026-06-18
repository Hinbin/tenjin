# frozen_string_literal: true

# ThemeHelper — renders the reskinnable theme onto the layout (Plan 01, Phase 0).
#
# The body carries data-skin / data-palette / data-mode + an inline style="" of resolved CSS
# vars, server-rendered from the user's Selection so there is no flash of the default theme. The
# `theme` Stimulus controller (also attached to body) applies any client-side override and drives
# live switching.
module ThemeHelper
  # The current user's resolved {skin, palette, dark}. Falls back to defaults when logged out.
  def theme_selection
    @theme_selection ||= Theme::Selection.for(current_user)
  end

  def theme_mode
    theme_selection.dark ? 'dark' : 'light'
  end

  # Inline CSS-var string for <body style="…">.
  def theme_inline_style
    Theme::Resolver.style_string(
      skin: theme_selection.skin,
      palette: theme_selection.palette,
      dark: theme_selection.dark
    )
  end

  # Merge the theme Stimulus controller alongside the per-page controller (controller_name).
  def theme_controllers(*extra)
    [controller_name, 'theme', *extra].compact_blank.join(' ')
  end

  # Full resolved catalog for client-side live switching (styleguide / settings only — do NOT put
  # this on the global body; it's ~32 var-maps). Shape:
  #   { "arcade" => { "0" => { "dark" => {vars}, "light" => {vars} }, … }, … }
  def theme_catalog_json
    Theme::SkinCatalog.skin_ids.index_with do |skin|
      Theme::SkinCatalog.palettes(skin).each_index.index_with do |idx|
        {
          'dark' => Theme::Resolver.css_vars(skin: skin, palette: idx, dark: true),
          'light' => Theme::Resolver.css_vars(skin: skin, palette: idx, dark: false)
        }
      end.transform_keys(&:to_s)
    end.to_json
  end
end
