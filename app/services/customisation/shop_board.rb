# frozen_string_literal: true

# Customisation::ShopBoard — the Reward Shop's read model (Plan 01, Phase 4).
#
# Groups every equip-slot customisation into ordered categories, each item tagged with the viewing
# user's owned/equipped/locked state. The view renders this verbatim — no DB logic in the template.
# Ownership is preloaded (one unlock query + one equipped query) to avoid N+1s.
#
# The Skins category is special: each skin item carries its own palettes (a recolour belongs to a
# skin) and a tagline, so the view can "sell" the skin and group its palettes under it. The five
# cosmetic slots (avatar, nameplate, … from Cosmetic::Catalog) stay flat.
#
#   board = Customisation::ShopBoard.call(current_user)
#   board.categories  # => [Category(type:, en:, jp:, glyph:, blurb:, items:[Item,…]), …]
#   board.wallet      # => spendable challenge_points
class Customisation::ShopBoard < ApplicationService
  Category = Struct.new(:type, :en, :jp, :glyph, :blurb, :items, keyword_init: true)
  # The light/dark switch shown in the shop header: the user's current mode, whether they own the
  # light-mode perk yet, and the perk record (so the view can render a buy button while locked).
  ModeStatus = Struct.new(:dark, :owned, :customisation, :cost, keyword_init: true)
  Item = Struct.new(:customisation, :name, :value, :cost, :glyph, :token,
                    :owned, :equipped, :gated, :req, :tagline, :palettes, keyword_init: true) do
    # achievement-gated and not yet earned (display-only, v1)
    def locked? = gated && !owned
    # purchasable with points
    def buyable? = !owned && !gated
  end

  SKIN_META = { en: 'Skins', jp: 'スキン', glyph: 'globe',
                blurb: 'The whole look — fonts, shapes & feel. Each skin brings its own palettes.' }.freeze

  # The theme slots (not in Cosmetic::Catalog) whose Customisation records must be preloaded.
  THEME_TYPES = %w[skin palette].freeze

  def initialize(user)
    super()
    @user = user
  end

  def call
    result(success: true, categories: categories, wallet: @user.challenge_points.to_i, mode: mode_status)
  end

  private

  def mode_status
    record = Customisation.light_mode.first
    ModeStatus.new(dark: Theme::Selection.for(@user).dark,
                   owned: record.present? && @user.owns?(record),
                   customisation: record, cost: record&.cost.to_i)
  end

  def categories
    [skins_category] + Cosmetic::Catalog.types.map { |type| cosmetic_category(type) }
  end

  # ── Skins (with their palettes nested) ──────────────────────────────────────
  def skins_category
    items = Theme::SkinCatalog.skin_ids.filter_map { |skin| build_skin_item(skin) }
    Category.new(type: 'skin', en: SKIN_META[:en], jp: SKIN_META[:jp], glyph: SKIN_META[:glyph],
                 blurb: SKIN_META[:blurb], items: items)
  end

  def build_skin_item(skin)
    record = lookup('skin')[skin]
    return unless record

    Item.new(**item_attrs('skin', { value: skin }, record),
             tagline: Theme::SkinCatalog.meta(skin)[:tagline],
             palettes: palette_items(skin))
  end

  def palette_items(skin)
    Theme::SkinCatalog.palettes(skin).each_index.filter_map do |index|
      record = lookup('palette')["#{skin}:#{index}"]
      record && Item.new(**item_attrs('palette', { value: "#{skin}:#{index}" }, record))
    end
  end

  # ── Cosmetic slots (flat) ───────────────────────────────────────────────────
  def cosmetic_category(type)
    category = Cosmetic::Catalog.category(type)
    items = Cosmetic::Catalog.items(type).filter_map { |spec| build_item(type, spec) }
    Category.new(type: type, en: category[:en], jp: category[:jp], glyph: category[:glyph],
                 blurb: category[:blurb], items: items)
  end

  # spec carries at least :value and optionally :glyph/:tok (avatars). The persisted Customisation
  # is the source of truth for name/cost/req; skip any value not yet seeded.
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

  def lookup(type)
    records_by_type[type] ||= {}
  end

  def records_by_type
    @records_by_type ||= Customisation.where(customisation_type: THEME_TYPES + Cosmetic::Catalog.types)
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
