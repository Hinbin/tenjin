# frozen_string_literal: true

# Customisation::SeedCosmetics — idempotent catalog seeder for the Phase 4 reward shop.
#
# Ports the theme slots (skins + palettes, from Theme::SkinCatalog) and the five cosmetic slots
# (from Cosmetic::Catalog, itself a verbatim port of the prototype SHOP_CATS). Re-runnable:
# find_or_initialize_by (customisation_type, value) so running it again updates in place rather
# than duplicating.
#
# Pricing (decision #2): every skin and each skin's base palette (index 0) are FREE
# (purchasable:false, cost:0 — treated as owned by everyone, no unlock rows). Extra palettes and
# the cost-bearing cosmetics are purchasable. Gated items (a non-nil req) are seeded but NOT
# directly buyable in v1 (decision #4) — they show as locked.
#
#   Customisation::SeedCosmetics.call                  # seed + default-equip backfill
#   Customisation::SeedCosmetics.call(backfill: false) # seed only
class Customisation::SeedCosmetics < ApplicationService
  PALETTE_COST = 300 # extra palettes (index >= 1); the prototype prices skins/palettes only by tier
  LIGHT_MODE_COST = 100 # cheapest item in the shop — a low-cost perk that unlocks the light/dark toggle

  def initialize(options = {})
    super()
    @backfill = options.fetch(:backfill, true)
  end

  def call
    seed_skins
    seed_palettes
    seed_cosmetics
    seed_scenes
    seed_motions
    seed_light_mode
    backfill_default_equips if @backfill
    result(success: true)
  end

  private

  def seed_skins
    Theme::SkinCatalog.skin_ids.each do |skin|
      upsert('skin', skin, name: Theme::SkinCatalog.meta(skin)[:label], cost: 0)
    end
  end

  def seed_palettes
    Theme::SkinCatalog.skin_ids.each { |skin| seed_palettes_for(skin) }
  end

  def seed_palettes_for(skin)
    label = Theme::SkinCatalog.meta(skin)[:label]
    Theme::SkinCatalog.palettes(skin).each_with_index do |palette, index|
      upsert('palette', "#{skin}:#{index}",
             name: "#{label} · #{palette[:label]}", cost: index.zero? ? 0 : PALETTE_COST)
    end
  end

  def seed_cosmetics
    Cosmetic::Catalog.types.each { |type| seed_cosmetics_for(type) }
  end

  # Skin-locked Scenes: one `scene` row per skin/scene, value composite "<skin>:<id>" (like palette).
  def seed_scenes
    Cosmetic::SceneCatalog.skins.each do |skin|
      Cosmetic::SceneCatalog.scenes_for(skin).each do |item|
        upsert('scene', "#{skin}:#{item[:value]}", name: item[:name], cost: item[:cost].to_i, req: item[:req])
      end
    end
  end

  # Skin-locked Atmospheres: one `motion` row per skin/motion, value composite "<skin>:<id>".
  def seed_motions
    Cosmetic::MotionCatalog.skins.each do |skin|
      Cosmetic::MotionCatalog.motions_for(skin).each do |item|
        upsert('motion', "#{skin}:#{item[:value]}", name: item[:name], cost: item[:cost].to_i, req: item[:req])
      end
    end
  end

  # The light-mode perk: a single non-slot Customisation. Students start locked to dark mode and buy
  # this once to unlock the light/dark toggle in the shop header (Theme::Selection reads dark_mode).
  def seed_light_mode
    upsert('light_mode', 'light_mode', name: 'Light Mode', cost: LIGHT_MODE_COST)
  end

  def seed_cosmetics_for(type)
    Cosmetic::Catalog.items(type).each do |item|
      upsert(type, item[:value], name: item[:name], cost: item[:cost].to_i, req: item[:req])
    end
  end

  # Free starters (cost 0, no req) and gated items (req present) are not directly buyable, so they
  # are seeded purchasable:false; only cost-bearing, ungated items are purchasable.
  def upsert(type, value, name:, cost:, req: nil)
    record = Customisation.find_or_initialize_by(customisation_type: type, value: value)
    record.assign_attributes(name: name, cost: cost, req: req, purchasable: cost.positive? && req.blank?)
    record.save!
  end

  # Belt-and-suspenders: every student should resolve to a valid skin + palette even though
  # Theme::Selection already falls back to defaults. Equip the free default skin/palette for any
  # student who has none. Cosmetic slots fall back gracefully in the render helpers, so they are
  # left unequipped until the student chooses.
  def backfill_default_equips
    skin = Customisation.skin.find_by(value: Theme::SkinCatalog::DEFAULT_SKIN)
    palette = Customisation.palette.find_by(
      value: "#{Theme::SkinCatalog::DEFAULT_SKIN}:#{Theme::SkinCatalog::DEFAULT_PALETTE}"
    )
    User.student.find_each do |student|
      equip_default(student, skin)
      equip_default(student, palette)
    end
  end

  def equip_default(user, customisation)
    return if customisation.nil?
    return if user.equipped(customisation.customisation_type)

    Customisation::EquipCustomisation.call(user, customisation)
  end
end
