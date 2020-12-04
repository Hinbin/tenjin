# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation, type: :model do
  it 'sets a retired customisation to be unpurchasable' do
    invalid_customisation = build(:customisation, retired: true,
                                                  purchasable: true, customisation_type: 'leaderboard_icon')
    invalid_customisation.save!
    invalid_customisation.reload
    expect(invalid_customisation.retired).to eq(true)
  end

  it 'requires an image for a dashboard style' do
    invalid_customisation = build(:customisation, image: nil)
    expect(invalid_customisation).not_to be_valid
  end

  it 'does not require an image for an icon' do
    invalid_customisation = build(:customisation, customisation_type: 'leaderboard_icon', image: nil)
    expect(invalid_customisation).to be_valid
  end
end
