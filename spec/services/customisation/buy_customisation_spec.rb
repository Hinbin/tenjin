# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customisation::BuyCustomisation, :default_creates do
  let(:customisation) { create(:customisation, cost: 5) }
  let(:old_customisation) { create(:customisation, cost: 2) }
  let(:old_customisation_unlock) do
    create(:customisation_unlock, customisation: old_customisation, user: student)
  end

  before do
    student.update_attribute(:challenge_points, 10)
    create(:customisation_unlock, customisation: old_customisation, user: student)
  end

  context 'when buying a new customisation' do
    it 'creates the correct customisation unlock' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
    end

    it 'sets the new customisation unlock to active' do
      described_class.new(student, customisation).call
      expect(ActiveCustomisation.where(customisation: customisation).count).to eq(1)
    end

    it 'sets the old customisation unlock to inactive' do
      described_class.new(student, customisation).call
      expect(ActiveCustomisation.where(customisation: old_customisation).count).to eq(0)
    end

    it 'deducts the correct amount of challenge points' do
      described_class.new(student, customisation).call
      expect(student.challenge_points).to eq(5)
    end
  end

  context 'when moving from the default customisation' do
    before do
      CustomisationUnlock.all.destroy_all
    end

    it 'handles not having an existing customisation unlock' do
      described_class.new(student, customisation).call
      expect(CustomisationUnlock.where(customisation: customisation).count).to eq(1)
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

  context 'when buying a free cosmetic (cost 0, decision #2)' do
    let(:free_avatar) { create(:customisation, customisation_type: 'avatar', value: 'torii', cost: 0, image: nil) }

    it 'equips it without charging or creating an unlock row' do
      expect { described_class.new(student, free_avatar).call }.not_to change(student, :challenge_points)
      expect(student.equipped_value(:avatar)).to eq('torii')
      expect(CustomisationUnlock.where(customisation: free_avatar)).to be_empty
    end
  end

  context 'when buying a paid cosmetic' do
    let(:avatar) { create(:customisation, customisation_type: 'avatar', value: 'gem', cost: 4, image: nil) }

    it 'auto-equips it after the unlock' do
      described_class.new(student, avatar).call
      expect(student.equipped_value(:avatar)).to eq('gem')
    end
  end

  context 'when buying the light-mode perk' do
    let(:light_mode) { create(:customisation, customisation_type: 'light_mode', value: 'light_mode', cost: 4, image: nil) }

    it 'unlocks it and switches the user straight into light mode' do
      described_class.new(student, light_mode).call
      expect(student.owns?(light_mode)).to be(true)
      expect(student.reload.dark_mode).to be(false)
    end

    it 'does not create a stray active-customisation row for the perk' do
      described_class.new(student, light_mode).call
      expect(ActiveCustomisation.where(customisation: light_mode)).to be_empty
    end
  end

  context 'when buying something I have already bought' do
    before do
      create(:customisation_unlock, customisation: customisation, user: student)
    end

    it 'does not cost anything' do
      described_class.new(student, customisation).call
      expect { student.reload }.not_to change(student, :challenge_points)
    end

    it 'creates a new entry in the active customisaion table' do
      described_class.new(student, customisation).call
      expect(ActiveCustomisation.where(customisation: customisation).count).to eq(1)
    end

    it 'removes the old entry in the active customisation table' do
      described_class.new(student, customisation).call
      expect(ActiveCustomisation.where(customisation: old_customisation).count).to eq(0)
    end
  end
end
