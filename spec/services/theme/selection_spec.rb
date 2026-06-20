# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Theme::Selection, :default_creates do
  def equip(type, value, dark: nil)
    customisation = create(:customisation, customisation_type: type, value: value, cost: 0, image: nil)
    Customisation::EquipCustomisation.call(student, customisation)
    student.update!(dark_mode: dark) unless dark.nil?
  end

  describe '.for' do
    it 'falls back to the defaults when nothing is equipped' do
      selection = described_class.for(student)
      expect(selection.skin).to eq(Theme::SkinCatalog::DEFAULT_SKIN)
      expect(selection.palette).to eq(Theme::SkinCatalog::DEFAULT_PALETTE)
    end

    it 'returns the default selection for a nil user' do
      expect(described_class.for(nil).skin).to eq(Theme::SkinCatalog::DEFAULT_SKIN)
    end

    it 'resolves the skin + palette from the equipped active customisations' do
      equip('skin', 'kawaii')
      equip('palette', 'kawaii:2')
      selection = described_class.for(student)
      expect(selection.skin).to eq('kawaii')
      expect(selection.palette).to eq(2)
    end

    it 'ignores a palette belonging to a different skin than the equipped one' do
      equip('skin', 'kawaii')
      equip('palette', 'arcade:3') # stale palette from another skin
      expect(described_class.for(student).palette).to eq(Theme::SkinCatalog::DEFAULT_PALETTE)
    end

    it 'ignores an unknown skin value' do
      equip('skin', 'not-a-skin')
      expect(described_class.for(student).skin).to eq(Theme::SkinCatalog::DEFAULT_SKIN)
    end

    it 'reads dark mode from the user' do
      student.update!(dark_mode: false)
      expect(described_class.for(student).dark).to be(false)
    end
  end
end
