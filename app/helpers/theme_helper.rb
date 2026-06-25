# frozen_string_literal: true

# ThemeHelper — renders the reskinnable theme onto the layout (Plan 01, Phase 0).
#
# The body carries data-skin / data-palette / data-mode + an inline style="" of resolved CSS
# vars, server-rendered from the user's Selection so there is no flash of the default theme. The
# `theme` Stimulus controller (also attached to body) applies any client-side override and drives
# live switching.
module ThemeHelper
  # The current user's resolved {skin, palette, dark}. Falls back to defaults when logged out — but a
  # returning visitor who previously logged in had their skin stored in a cookie, so honour that on the
  # logged-out landing page (see #guest_theme_selection and ApplicationController#remember_theme_skin).
  def theme_selection
    return @theme_selection if defined?(@theme_selection)

    selection = Theme::Selection.for(current_user, preview: current_preview_customisation)
    @theme_selection = current_user ? selection : guest_theme_selection(selection)
  end

  # Per-skin landing-page slogan (the old fixed "Learn, Compete, Succeed"). Arcade keeps the original;
  # every other skin gets a 3-beat line in its own voice. Unknown skin → the arcade default.
  HOME_SLOGANS = {
    'arcade' => 'Learn. Compete. Succeed.',
    'zen' => 'Breathe. Focus. Master.',
    'kawaii' => 'Play. Practise. Shine.',
    'famicom' => 'Press Start. Level Up. Win.',
    'pitch' => 'Kick Off. Compete. Triumph.',
    'manga' => 'Train. Battle. Prevail.',
    'street' => 'Practise. Battle. Rise.'
  }.freeze

  def home_slogan(skin = current_skin)
    HOME_SLOGANS[skin] || HOME_SLOGANS[Theme::SkinCatalog::DEFAULT_SKIN]
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

  # The active skin id (falls back to default when no user session).
  def current_skin
    theme_selection.skin
  end

  # The equipped Scene id for the active skin ('none' when nothing/foreign-skin equipped).
  def current_scene
    theme_selection.scene
  end

  # The CSS token that tints the active scene's motif (e.g. 'var(--n1)'); nil when no scene.
  def current_scene_token
    return nil if current_scene.blank? || current_scene == 'none'

    "var(--#{Cosmetic::SceneCatalog.token(current_skin, current_scene)})"
  end

  # The equipped global Scene FX id ('glow'/'flicker'/… or 'none'). Animates the equipped Scene.
  def current_scene_fx
    theme_selection.scene_fx
  end

  # The equipped Atmosphere id for the active skin ('none' when nothing/foreign-skin equipped).
  def current_motion
    theme_selection.motion
  end

  # The CSS token that tints the active motion's particles (e.g. 'var(--n1)'); nil when no motion.
  def current_motion_token
    return nil if current_motion.blank? || current_motion == 'none'

    "var(--#{Cosmetic::MotionCatalog.token(current_skin, current_motion)})"
  end

  # Logo mark glyph: kawaii → heart, famicom → star, pitch → ball, manga → bolt,
  # street → crown, others (arcade/zen) → torii.
  def current_skin_logo_glyph
    case current_skin
    when 'kawaii'  then :heart
    when 'famicom' then :star
    when 'pitch'   then :ball
    when 'manga'   then :bolt
    when 'street'  then :crown
    else                :torii
    end
  end

  # data-motion attribute value for <body>: "true" when motion is on (default), "false" when off.
  # Reads the user's stored motion_pref; falls back to true (motion on) for guests.
  def motion_pref_data
    return 'true' unless current_user.respond_to?(:motion_pref)

    current_user.motion_pref ? 'true' : 'false'
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

  private

  # Skin/mode a guest sees: arcade defaults, overridden by the `tj_skin`/`tj_mode` cookies a previously
  # signed-in visitor left behind. Only the base palette is used (guests own nothing to scope to).
  def guest_theme_selection(default_selection)
    skin = cookies[:tj_skin]
    return default_selection unless Theme::SkinCatalog.skin?(skin)

    Theme::Selection.new(
      skin: skin,
      palette: Theme::SkinCatalog::DEFAULT_PALETTE,
      dark: cookies[:tj_mode].present? ? cookies[:tj_mode] != 'light' : default_selection.dark,
      scene: 'none', motion: 'none', scene_fx: 'none'
    )
  end
end
