# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cosmetic::SceneCatalog do
  it 'covers every skin in the catalog' do
    expect(described_class.skins).to match_array(Theme::SkinCatalog.skin_ids)
  end

  it 'starts each skin with a free none default' do
    described_class.skins.each do |skin|
      first = described_class.scenes_for(skin).first
      expect(first[:value]).to eq('none')
      expect(first[:cost]).to eq(0)
    end
  end

  it 'looks up a scene and its tint token' do
    expect(described_class.scene('zen', 'tree')[:name]).to eq('Blossom Tree')
    expect(described_class.token('zen', 'tree')).to eq('n1')
    expect(described_class.token('zen', 'unknown')).to eq('n1') # falls back
  end
end
