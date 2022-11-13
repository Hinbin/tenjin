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
end
