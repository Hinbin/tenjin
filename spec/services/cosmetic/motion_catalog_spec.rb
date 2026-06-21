# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cosmetic::MotionCatalog do
  it 'covers every skin in the catalog' do
    expect(described_class.skins).to match_array(Theme::SkinCatalog.skin_ids)
  end

  it 'starts each skin with a free none default' do
    described_class.skins.each do |skin|
      first = described_class.motions_for(skin).first
      expect(first[:value]).to eq('none')
      expect(first[:cost]).to eq(0)
    end
  end

  it 'looks up a motion and its tint token' do
    expect(described_class.motion('zen', 'petals')[:name]).to eq('Cherry Blossom')
    expect(described_class.token('zen', 'petals')).to eq('n1')
    expect(described_class.token('zen', 'unknown')).to eq('n1') # falls back
  end
end
