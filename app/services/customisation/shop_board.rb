# frozen_string_literal: true

# Customisation::ShopBoard — the Reward Shop's read model (Plan 01, Phase 4).
#
# Groups every equip-slot customisation (skins + palettes from Theme::SkinCatalog, and the five
# cosmetic slots from Cosmetic::Catalog) into ordered categories, each item tagged with the
# viewing user's owned/equipped/locked state. The view renders this verbatim — no DB logic in the
# template. Ownership is preloaded (one unlock query + one equipped query) to avoid N+1s.
#
#   board = Customisation::ShopBoard.call(current_user)
#   board.categories  # => [Category(type:, en:, jp:, glyph:, blurb:, items:[Item,…]), …]
#   board.wallet      # => spendable challenge_points
class Customisation::ShopBoard < ApplicationService
  Category = Struct.new(:type, :en, :jp, :glyph, :blurb, :items, keyword_init: true)
  Item = Struct.new(:customisation, :name, :value, :cost, :glyph, :token,
                    :owned, :equipped, :gated, :req, keyword_init: true) do
    # achievement-gated and not yet earned (display-only, v1)
    def locked? = gated && !owned
    # purchasable with points
    def buyable? = !owned && !gated
  end

  # Theme slots are not in Cosmetic::Catalog (Theme::SkinCatalog owns them); supply their chrome.
  THEME_META = {
    'skin' => { en: 'Skins', jp: 'スキン', glyph: 'globe', blurb: 'The whole look — fonts, shapes & feel.' },
    'palette' => { en: 'Palettes', jp: '色', glyph: 'gem', blurb: 'Recolour your chosen skin.' }
  }.freeze

  def initialize(user)
    super()
    @user = user
  end

  def call
    result(success: true, categories: categories, wallet: @user.challenge_points.to_i)
  end

  private

  def categories
    THEME_META.each_key.map { |type| theme_category(type) } +
      Cosmetic::Catalog.types.map { |type| cosmetic_category(type) }
  end

  def theme_category(type)
    meta = THEME_META.fetch(type)
    values = type == 'skin' ? skin_values : palette_values
    build(type, meta, values.map { |value| { value: value } })
  end

  def cosmetic_category(type)
    category = Cosmetic::Catalog.category(type)
    build(type, category, Cosmetic::Catalog.items(type))
  end

  def build(type, meta, item_specs)
    items = item_specs.filter_map { |spec| build_item(type, spec) }
    Category.new(type: type, en: meta[:en], jp: meta[:jp], glyph: meta[:glyph], blurb: meta[:blurb], items: items)
  end

  # spec carries at least :value (theme slots) and optionally :glyph/:tok (avatars). The persisted
  # Customisation is the source of truth for name/cost/req; skip any value not yet seeded.
  def build_item(type, spec)
    record = lookup(type)[spec[:value]]
    record && Item.new(**item_attrs(type, spec, record))
  end

  def item_attrs(type, spec, record)
    { customisation: record, name: record.name, value: record.value, cost: record.cost.to_i,
      glyph: spec[:glyph], token: spec[:tok] && "var(--#{spec[:tok]})",
      owned: owned?(record), equipped: equipped_values[type] == record.value,
      gated: record.gated?, req: record.req }
  end

  def owned?(record)
    record.free? || unlocked_ids.include?(record.id)
  end

  def skin_values
    Theme::SkinCatalog.skin_ids
  end

  def palette_values
    Theme::SkinCatalog.skin_ids.flat_map do |skin|
      Theme::SkinCatalog.palettes(skin).each_index.map { |index| "#{skin}:#{index}" }
    end
  end

  def lookup(type)
    records_by_type[type] ||= {}
  end

  def records_by_type
    @records_by_type ||= Customisation.where(customisation_type: THEME_META.keys + Cosmetic::Catalog.types)
                                      .group_by(&:customisation_type)
                                      .transform_values { |records| records.index_by(&:value) }
  end

  def unlocked_ids
    @unlocked_ids ||= @user.customisation_unlocks.pluck(:customisation_id).to_set
  end

  def equipped_values
    @equipped_values ||= ActiveCustomisation.where(user: @user).includes(:customisation)
                                            .to_h do |active|
      [active.customisation.customisation_type, active.customisation.value]
    end
  end
end
