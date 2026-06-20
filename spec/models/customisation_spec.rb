# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation, type: :model do
  it 'sets a retired customisation to be unpurchasable' do
    invalid_customisation = build(:customisation, retired: true,
                                                  purchasable: true, customisation_type: 'skin')
    invalid_customisation.save!
    invalid_customisation.reload
    expect(invalid_customisation.retired).to eq(true)
  end

  describe 'Phase 4 equip-slot enum' do
    it 'keeps the cosmetic slots at their original values (legacy 0/1/2 retired)' do
      expect(described_class.customisation_types).to eq(
        'skin' => 3, 'palette' => 4, 'avatar' => 5, 'nameplate' => 6,
        'name_effect' => 7, 'answer_effect' => 8, 'streak_aura' => 9, 'light_mode' => 10
      )
    end

    it 'scopes the cosmetic equip slots' do
      skin = create(:customisation, customisation_type: 'skin', cost: 0)
      expect(described_class.cosmetic).to include(skin)
    end
  end

  describe '#free?' do
    it 'is true for a cost-0 item with no req' do
      expect(build(:customisation, customisation_type: 'skin', cost: 0, image: nil)).to be_free
    end

    it 'is false for a cost-bearing item' do
      expect(build(:customisation, customisation_type: 'avatar', cost: 200, image: nil)).not_to be_free
    end

    it 'is false for a gated cost-0 item (locked, not given away)' do
      gated = build(:customisation, customisation_type: 'avatar', cost: 0, req: 'Win the cup', image: nil)
      expect(gated).not_to be_free
    end
  end

  describe '#gated?' do
    it 'is true only when req is present' do
      expect(build(:customisation, req: 'x', image: nil)).to be_gated
      expect(build(:customisation, req: nil, image: nil)).not_to be_gated
    end
  end
end
