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
end
