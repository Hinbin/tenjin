# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::EquipCustomisation, :default_creates do
  def cosmetic(type:, value:, cost: 0, req: nil)
    create(:customisation, customisation_type: type, value: value, cost: cost, req: req, image: nil)
  end

  let(:torii)  { cosmetic(type: 'avatar', value: 'torii') } # free
  let(:gem)    { cosmetic(type: 'avatar', value: 'gem', cost: 300) }
  let(:plate)  { cosmetic(type: 'nameplate', value: 'bar', cost: 150) }

  describe 'one active per slot' do
    before do
      create(:customisation_unlock, customisation: gem, user: student)
      described_class.new(student, torii).call
    end

    it 'replaces the previous active in the same slot' do
      described_class.new(student, gem).call
      expect(student.equipped_value(:avatar)).to eq('gem')
    end

    it 'keeps exactly one active row for the slot' do
      described_class.new(student, gem).call
      slot = Customisation.customisation_types['avatar']
      count = ActiveCustomisation.joins(:customisation)
                                 .where(user: student, customisations: { customisation_type: slot }).count
      expect(count).to eq(1)
    end

    it 'does not disturb a different slot' do
      create(:customisation_unlock, customisation: plate, user: student)
      described_class.new(student, plate).call
      expect(student.equipped_value(:avatar)).to eq('torii')
      expect(student.equipped_value(:nameplate)).to eq('bar')
    end
  end

  describe 'ownership gating' do
    it 'equips a free item with no unlock row (decision #2)' do
      result = described_class.new(student, torii).call
      expect(result.success?).to be(true)
      expect(student.equipped_value(:avatar)).to eq('torii')
    end

    it 'refuses an unowned paid item' do
      result = described_class.new(student, gem).call
      expect(result.success?).to be(false)
      expect(ActiveCustomisation.where(user: student)).to be_empty
    end

    it 'refuses a gated item that has not been earned' do
      trophy = cosmetic(type: 'avatar', value: 'trophy', cost: 0, req: 'Win the cup')
      expect(described_class.new(student, trophy).call.success?).to be(false)
    end

    it 'reports a missing customisation' do
      expect(described_class.new(student, nil).call.success?).to be(false)
    end
  end
end
