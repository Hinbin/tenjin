require 'rails_helper'

RSpec.describe Customisation::BuyCustomisation do
  include_context 'default_creates'

  let(:customisation) { create(:customisation, cost: 5, customisation_type: 0) }

  before do
    student.update_attribute(:challenge_points, 10)
  end

  context 'when buying a new dashboard style' do
    it 'completes the purchase' do
      described_class.new(student, customisation).call
      expect(student.dashboard_style).to eq(customisation.value)
    end

    it 'deducts the correct amount of challenge points' do
      described_class.new(student, customisation).call
      expect(student.challenge_points).to eq(5)
    end
  end

  context 'when buying something I do not have points for' do
    before do
      student.update_attribute(:challenge_points, 3)
    end

    it 'alerts me that I do not have enough points' do
      expect(described_class.new(student, customisation).call.errors).to eq('You do not have enough points')
    end
  end
end
