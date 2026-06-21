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

    it 'defaults the scene to none when nothing is equipped' do
      expect(described_class.for(student).scene).to eq('none')
    end

    it 'resolves the equipped scene for the active skin' do
      equip('skin', 'zen')
      equip('scene', 'zen:tree')
      expect(described_class.for(student).scene).to eq('tree')
    end

    it 'ignores a scene belonging to a different skin than the equipped one' do
      equip('skin', 'zen')
      equip('scene', 'arcade:sun') # stale scene from another skin
      expect(described_class.for(student).scene).to eq('none')
    end

    it 'defaults the motion to none when nothing is equipped' do
      expect(described_class.for(student).motion).to eq('none')
    end

    it 'resolves the equipped motion for the active skin' do
      equip('skin', 'zen')
      equip('motion', 'zen:petals')
      expect(described_class.for(student).motion).to eq('petals')
    end

    it 'ignores a motion belonging to a different skin than the equipped one' do
      equip('skin', 'zen')
      equip('motion', 'arcade:rain') # stale motion from another skin
      expect(described_class.for(student).motion).to eq('none')
    end

    it 'resolves the global scene_fx slot (flat, no skin filtering)' do
      equip('scene_fx', 'glow')
      expect(described_class.for(student).scene_fx).to eq('glow')
    end

    it 'falls back to none for an unknown scene_fx value' do
      equip('scene_fx', 'not-an-fx')
      expect(described_class.for(student).scene_fx).to eq('none')
    end
  end

  describe '.for with a preview (try-before-you-buy)' do
    def cust(type, value)
      create(:customisation, customisation_type: type, value: value, cost: 0, image: nil)
    end

    it 'layers a previewed skin over the equipped selection' do
      selection = described_class.for(student, preview: cust('skin', 'kawaii'))
      expect(selection.skin).to eq('kawaii')
      expect(selection.palette).to eq(Theme::SkinCatalog::DEFAULT_PALETTE)
    end

    it 'layers a previewed colour scheme (palette), switching to its skin' do
      selection = described_class.for(student, preview: cust('palette', 'kawaii:2'))
      expect(selection).to have_attributes(skin: 'kawaii', palette: 2)
    end

    it 'resets the other skin-locked slots when previewing a foreign skin' do
      equip('skin', 'zen')
      equip('scene', 'zen:tree')
      selection = described_class.for(student, preview: cust('skin', 'kawaii'))
      expect(selection).to have_attributes(skin: 'kawaii', scene: 'none', motion: 'none')
    end

    it 'switches the skin to match a previewed scene' do
      selection = described_class.for(student, preview: cust('scene', 'zen:tree'))
      expect(selection).to have_attributes(skin: 'zen', scene: 'tree', motion: 'none')
    end

    it 'keeps the equipped palette when previewing a scene on the same skin' do
      equip('skin', 'zen')
      equip('palette', 'zen:2')
      selection = described_class.for(student, preview: cust('scene', 'zen:tree'))
      expect(selection).to have_attributes(skin: 'zen', palette: 2, scene: 'tree')
    end

    it 'switches the skin to match a previewed motion' do
      selection = described_class.for(student, preview: cust('motion', 'zen:petals'))
      expect(selection).to have_attributes(skin: 'zen', motion: 'petals', scene: 'none')
    end

    it 'preserves dark mode while previewing' do
      student.update!(dark_mode: false)
      expect(described_class.for(student, preview: cust('skin', 'kawaii')).dark).to be(false)
    end

    it 'ignores a non-previewable customisation type' do
      selection = described_class.for(student, preview: cust('avatar', 'gem'))
      expect(selection.skin).to eq(Theme::SkinCatalog::DEFAULT_SKIN)
    end
  end
end
