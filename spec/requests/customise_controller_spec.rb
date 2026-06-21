# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'submitting a customisation', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school, challenge_points: 100) }
  let(:customisation) { create(:customisation) }

  before do
    sign_in student
  end

  context 'when selecting a customisation type that does not exist' do
    subject do
      post buy_customisation_path(id: rand(200..300))
    end

    it { is_expected.to redirect_to(show_available_customisations_path) }
  end

  context 'when equipping an owned cosmetic' do
    let(:avatar) { create(:customisation, customisation_type: 'avatar', value: 'torii', cost: 0, image: nil) }

    it 'equips it and redirects back to the shop' do
      post equip_customisation_path(avatar)
      expect(response).to redirect_to(show_available_customisations_path)
      expect(student.equipped_value(:avatar)).to eq('torii')
    end
  end

  context 'when equipping an item I do not own' do
    let(:avatar) { create(:customisation, customisation_type: 'avatar', value: 'gem', cost: 300, image: nil) }

    it 'does not equip it' do
      post equip_customisation_path(avatar)
      expect(student.equipped_value(:avatar)).to be_nil
    end
  end

  context 'when a Scene, Ambient Motion and Scene FX are equipped' do
    before do
      Customisation::SeedCosmetics.call(backfill: false)
      [['skin', 'zen'], ['scene', 'zen:tree'], ['motion', 'zen:petals'], ['scene_fx', 'glow']].each do |type, val|
        record = Customisation.find_by(customisation_type: type, value: val)
        create(:customisation_unlock, user: student, customisation: record) unless record.free?
        Customisation::EquipCustomisation.call(student, record)
      end
    end

    it 'renders the Scene, Ambient Motion and Scene FX layers in the shop backdrop' do
      get show_available_customisations_path

      expect(response.body).to include('tjs-scene')                 # scene motif layer
      expect(response.body).to include('data-scene-fx="glow"')      # scene FX on the scene
      expect(response.body).to include('data-controller="motion"')  # ambient motion layer
      expect(response.body).to include('data-motion-id-value="petals"')
    end
  end

  context 'when toggling the appearance mode' do
    let!(:light_mode) do
      create(:customisation, customisation_type: 'light_mode', value: 'light_mode', cost: 100, image: nil)
    end

    it 'renders the shop with the appearance toggle' do
      get show_available_customisations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Appearance')
    end

    it 'always lets a student switch back to dark mode' do
      student.update!(dark_mode: false)
      post toggle_mode_customisations_path(dark: 'true')
      expect(response).to redirect_to(show_available_customisations_path)
      expect(student.reload.dark_mode).to be(true)
    end

    it 'keeps light mode locked until the perk is bought' do
      post toggle_mode_customisations_path(dark: 'false')
      expect(student.reload.dark_mode).to be(true)
      expect(flash[:notice]).to match(/locked/i)
    end

    it 'switches to light mode once the perk is owned' do
      create(:customisation_unlock, customisation: light_mode, user: student)
      post toggle_mode_customisations_path(dark: 'false')
      expect(student.reload.dark_mode).to be(false)
    end
  end
end
