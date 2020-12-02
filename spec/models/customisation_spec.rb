# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation, type: :model do

  it 'sets a retired customisation to be unpurchasable' do
    invalid_customisation = build(:customisation, retired: true, purchasable: true)
    invalid_customisation.save
    invalid_customisation.reload
    expect(invalid_customisation.retired).to eq(true)
  end
end
