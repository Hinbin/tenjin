# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::SeedCosmetics, :default_creates do
  subject(:seed) { described_class.call(backfill: false) }

  it 'seeds every skin and palette from the SkinCatalog' do
    seed
    expect(Customisation.skin.count).to eq(Theme::SkinCatalog.skin_ids.size)
    palette_total = Theme::SkinCatalog.skin_ids.sum { |s| Theme::SkinCatalog.palettes(s).size }
    expect(Customisation.palette.count).to eq(palette_total)
  end

  it 'seeds every cosmetic slot from the Cosmetic::Catalog' do
    seed
    Cosmetic::Catalog.types.each do |type|
      expect(Customisation.where(customisation_type: type).count).to eq(Cosmetic::Catalog.items(type).size)
    end
  end

  it 'makes skins and base palettes free and not directly purchasable (decision #2)' do
    seed
    expect(Customisation.skin.pluck(:cost, :purchasable).uniq).to eq([[0, false]])
    base = Customisation.palette.find_by(value: 'arcade:0')
    expect(base).to have_attributes(cost: 0, purchasable: false)
  end

  it 'prices extra palettes and marks them purchasable' do
    seed
    extra = Customisation.palette.find_by(value: 'arcade:1')
    expect(extra).to have_attributes(cost: described_class::PALETTE_COST, purchasable: true)
  end

  it 'seeds gated items locked (req set, not purchasable)' do
    seed
    trophy = Customisation.avatar.find_by(value: 'trophy')
    expect(trophy).to have_attributes(purchasable: false, cost: 0)
    expect(trophy.req).to be_present
  end

  it 'is idempotent — re-running updates in place rather than duplicating' do
    seed
    expect { described_class.call(backfill: false) }.not_to change(Customisation, :count)
  end

  describe 'default-equip backfill' do
    it 'equips the default skin + palette for a student with none' do
      student
      described_class.call(backfill: true)
      expect(student.equipped_value(:skin)).to eq(Theme::SkinCatalog::DEFAULT_SKIN)
      expect(student.equipped_value(:palette)).to eq("#{Theme::SkinCatalog::DEFAULT_SKIN}:0")
    end
  end
end
