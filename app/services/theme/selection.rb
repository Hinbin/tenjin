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

    # `preview` (optional) is a Customisation::PREVIEWABLE_TYPES record the user is trying live but
    # does not own — its value is layered onto the resolved Selection without touching storage
    # (try-before-you-buy). nil → the plain equipped selection.
    def self.for(user, preview: nil)
      return default if user.nil?

      selection = new(
        skin: resolve_skin(user),
        palette: resolve_palette(user),
        dark: resolve_dark(user),
        scene: resolve_scene(user),
        motion: resolve_motion(user),
        scene_fx: resolve_scene_fx(user)
      )
      preview ? selection.with_preview(preview) : selection
    end

    # Layer a previewed Customisation onto this Selection, returning a NEW Selection (this one is
    # untouched). Only the previewed dimension changes; `dark` and the global `scene_fx` carry over.
    # The skin-locked slots (scene/motion) encode "<skin>:<id>"; previewing one switches the skin to
    # match so its structural look renders, and — when that differs from the current skin — clears
    # the other skin-locked slots the user can't own there (palette → base 0, scene/motion → none).
    def with_preview(customisation)
      case customisation.customisation_type
      when 'skin'    then preview_skin(customisation.value)
      when 'palette' then preview_palette(customisation.value)
      when 'scene'   then preview_locked(:scene, customisation.value)
      when 'motion'  then preview_locked(:motion, customisation.value)
      else self
      end
    end

    private

    def preview_skin(skin)
      return self if skin == self.skin

      dup_with(skin: skin, palette: SkinCatalog::DEFAULT_PALETTE, scene: 'none', motion: 'none')
    end

    # A palette belongs to a skin (value "<skin>:<index>"), so previewing one also switches to that
    # skin — mirroring EquipCustomisation. Switching skins clears the skin-locked scene/motion slots.
    def preview_palette(value)
      preview_skin_id, index = value.to_s.split(':')
      overrides = { skin: preview_skin_id, palette: index.to_i }
      overrides = overrides.merge(scene: 'none', motion: 'none') if preview_skin_id != skin
      dup_with(**overrides)
    end

    # type is :scene or :motion; value is "<skin>:<id>". Apply the previewed slot, clear the *other*
    # skin-locked slot, and reset the palette to base only when switching to a different skin.
    def preview_locked(type, value)
      preview_skin_id, id = value.to_s.split(':')
      other = type == :scene ? :motion : :scene
      overrides = { skin: preview_skin_id, type => id, other => 'none' }
      overrides[:palette] = SkinCatalog::DEFAULT_PALETTE if preview_skin_id != skin
      dup_with(**overrides)
    end

    def dup_with(**overrides)
      self.class.new(to_h.merge(overrides))
    end

    # ── storage reads (Phase 4 wires these to real data) ──────────────────────
    # (class methods below; `def self.` is unaffected by the `private` above — the storage reads are
    # made private via `private_class_method` at the end of the block.)

    # The user's equipped `skin` ActiveCustomisation value (e.g. "arcade"), else the role default:
    # students get the arcade default; teachers/admins (no equip flow yet) get the calmer zen look.
    def self.resolve_skin(user)
      skin = user.equipped_value(:skin)
      return skin if SkinCatalog.skin?(skin)

      user.respond_to?(:student?) && !user.student? ? SkinCatalog::DEFAULT_TEACHER_SKIN : SkinCatalog::DEFAULT_SKIN
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
