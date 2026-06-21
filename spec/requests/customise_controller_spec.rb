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

  context 'when a Scene, Atmosphere and Scene FX are equipped' do
    before do
      Customisation::SeedCosmetics.call(backfill: false)
      [['skin', 'zen'], ['scene', 'zen:tree'], ['motion', 'zen:petals'], ['scene_fx', 'glow']].each do |type, val|
        record = Customisation.find_by(customisation_type: type, value: val)
        create(:customisation_unlock, user: student, customisation: record) unless record.free?
        Customisation::EquipCustomisation.call(student, record)
      end
    end

    it 'renders the Scene, Atmosphere and Scene FX layers in the shop backdrop' do
      get show_available_customisations_path

      expect(response.body).to include('tjs-scene')                 # scene motif layer
      expect(response.body).to include('data-scene-fx="glow"')      # scene FX on the scene
      expect(response.body).to include('data-controller="motion"')  # atmosphere layer
      expect(response.body).to include('data-motion-id-value="petals"')
    end
  end

  context 'when trying a skin before buying (preview)' do
    let(:kawaii) { create(:customisation, customisation_type: 'skin', value: 'kawaii', cost: 0, image: nil) }

    it 'stores the preview and renders the previewed skin live' do
      post preview_customisation_path(kawaii)
      expect(session[:preview_customisation_id]).to eq(kawaii.id)

      get show_available_customisations_path
      expect(response.body).to include('data-skin="kawaii"')
    end

    it 'spends no points and creates no unlock/active rows' do
      post preview_customisation_path(kawaii)
      expect(student.reload.challenge_points).to eq(100)
      expect(CustomisationUnlock.count).to eq(0)
      expect(ActiveCustomisation.where(user: student).count).to eq(0)
    end

    it 'refuses to preview a non-previewable item' do
      avatar = create(:customisation, customisation_type: 'avatar', value: 'gem', cost: 300, image: nil)
      post preview_customisation_path(avatar)
      expect(session[:preview_customisation_id]).to be_nil
    end

    it 'clears the preview on stop' do
      post preview_customisation_path(kawaii)
      delete stop_preview_customisations_path
      expect(session[:preview_customisation_id]).to be_nil
    end

    it 'clears the preview once the item is bought' do
      post preview_customisation_path(kawaii)
      post buy_customisation_path(kawaii)
      expect(session[:preview_customisation_id]).to be_nil
    end

    it 'stamps the trial start so the cooldown can run' do
      expect { post preview_customisation_path(kawaii) }
        .to change { student.reload.cosmetic_trial_at }.from(nil)
    end

    it 'previews a colour scheme (palette) too' do
      palette = create(:customisation, customisation_type: 'palette', value: 'kawaii:1', cost: 300, image: nil)
      post preview_customisation_path(palette)
      expect(session[:preview_customisation_id]).to eq(palette.id)
    end
  end

  context 'when the trial cooldown is in effect' do
    let(:kawaii) { create(:customisation, customisation_type: 'skin', value: 'kawaii', cost: 0, image: nil) }
    let(:zen) { create(:customisation, customisation_type: 'skin', value: 'zen', cost: 0, image: nil) }

    it 'blocks starting a new trial until the cooldown lifts' do
      student.update!(cosmetic_trial_at: 1.minute.ago)
      post preview_customisation_path(kawaii)
      expect(session[:preview_customisation_id]).to be_nil
      expect(flash[:notice]).to match(/try another look/i)
    end

    it 'still lets a student switch looks within an already-active trial' do
      post preview_customisation_path(kawaii)          # starts the trial
      stamped_at = student.reload.cosmetic_trial_at
      post preview_customisation_path(zen)             # switch — allowed, no new stamp
      expect(session[:preview_customisation_id]).to eq(zen.id)
      expect(student.reload.cosmetic_trial_at).to eq(stamped_at)
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
