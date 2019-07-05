require 'rails_helper'

RSpec.describe 'updating schools', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school, challenge_points: 100) }
  let(:customisation) { create(:customisation) }

  before do
    sign_in admin
  end

  it 'redirects to the new passwords screen when resetting all passwords'
end
