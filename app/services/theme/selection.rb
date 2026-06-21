# frozen_string_literal: true

module Theme
  # Selection — resolves WHICH skin/palette/mode a given user has chosen.
  #
  # This is the single seam between storage and rendering. Phase 0 returns the defaults (the
  # styleguide drives switching client-side via localStorage). Phase 4 fills in the marked reads
  # so the choice comes from the user's equipped cosmetics (decision #1: skin/palette are
  # ActiveCustomisations) and `users.dark_mode`.
  #
  #   sel = Theme::Selection.for(current_user)
  #   Theme::Resolver.style_string(skin: sel.skin, palette: sel.palette, dark: sel.dark)
  Selection = Struct.new(:skin, :palette, :dark, :scene, :motion, :scene_fx, keyword_init: true) do
    def self.default
      new(skin: SkinCatalog::DEFAULT_SKIN, palette: SkinCatalog::DEFAULT_PALETTE,
          dark: SkinCatalog::DEFAULT_DARK, scene: 'none', motion: 'none', scene_fx: 'none')
    end

    def self.for(user)
      return default if user.nil?

      new(
        skin: resolve_skin(user),
        palette: resolve_palette(user),
        dark: resolve_dark(user),
        scene: resolve_scene(user),
        motion: resolve_motion(user),
        scene_fx: resolve_scene_fx(user)
      )
    end

    # ── storage reads (Phase 4 wires these to real data) ──────────────────────

    # The user's equipped `skin` ActiveCustomisation value (e.g. "arcade"), else the default.
    def self.resolve_skin(user)
      skin = user.equipped_value(:skin)
      SkinCatalog.skin?(skin) ? skin : SkinCatalog::DEFAULT_SKIN
    end

    # The equipped `palette` index for the chosen skin. The value is encoded "<skin>:<index>"; a
    # palette belonging to a different skin than the resolved one is ignored (falls back to base 0).
    def self.resolve_palette(user)
      skin = resolve_skin(user)
      pal_skin, index = user.equipped_value(:palette).to_s.split(':')
      pal_skin == skin ? index.to_i : SkinCatalog::DEFAULT_PALETTE
    end

    # `users.dark_mode` lands in Phase 0's migration; until then, default. Safe either way.
    def self.resolve_dark(user)
      return user.dark_mode if user.respond_to?(:dark_mode) && !user.dark_mode.nil?

      SkinCatalog::DEFAULT_DARK
    end

    # The equipped `scene` id for the chosen skin. The value is "<skin>:<id>"; a scene belonging to
    # a different skin than the resolved one is ignored (falls back to 'none'). Returns the id only.
    def self.resolve_scene(user)
      skin = resolve_skin(user)
      scene_skin, id = user.equipped_value(:scene).to_s.split(':')
      scene_skin == skin && Cosmetic::SceneCatalog.scene(skin, id) ? id : 'none'
    end

    # The equipped `motion` id for the chosen skin (value "<skin>:<id>"); foreign-skin → 'none'.
    def self.resolve_motion(user)
      skin = resolve_skin(user)
      motion_skin, id = user.equipped_value(:motion).to_s.split(':')
      motion_skin == skin && Cosmetic::MotionCatalog.motion(skin, id) ? id : 'none'
    end

    # The equipped global Scene FX id ('glow'/'flicker'/…); a flat slot, so no skin filtering.
    def self.resolve_scene_fx(user)
      fx = user.equipped_value(:scene_fx)
      Cosmetic::Catalog.item('scene_fx', fx) ? fx : 'none'
    end

    private_class_method :resolve_skin, :resolve_palette, :resolve_dark,
                         :resolve_scene, :resolve_motion, :resolve_scene_fx
  end
end
