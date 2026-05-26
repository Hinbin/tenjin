# frozen_string_literal: true

require "rails_helper"

RSpec.describe "submitting a customisation" do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school, challenge_points: 100) }
  before do
    sign_in student
  end

  context "when selecting a customisation type that does not exist" do
    subject do
      post buy_customisation_path(id: rand(200..300))
    end

    it { is_expected.to redirect_to(dashboard_path) }
  end

  context "when selecting a customisation that exists" do
    it "redirects to the dashboard" # pending — counterpart missing
  end
end
