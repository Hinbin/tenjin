# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Customisations", :default_creates, type: :request do
  let(:school_group_admin) { create(:school_group_admin) }

  describe "GET /system/customisations" do
    before do
      sign_in admin
      get system_customisations_path
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "renders the index" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it { expect(response).to redirect_to(root_path) }
    end
  end

  describe "admin route protection" do
    before do
      sign_in student
      get system_customisations_path
    end

    it "redirects users to the admin login" do
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "POST /system/customisations" do
    before { sign_in super_admin }

    it "creates a customisation" do
      expect {
        post system_customisations_path, params: {
          customisation: {
            name: "Test Customisation",
            value: "blue,heart",
            customisation_type: "leaderboard_icon",
            cost: 5,
            purchasable: true
          }
        }
      }.to change(Customisation, :count).by(1)
    end
  end

  describe "PATCH /system/customisations/:id" do
    before { sign_in super_admin }

    it "updates a customisation" do
      customisation = create(:customisation)
      patch system_customisation_path(customisation), params: {
        customisation: {name: "Renamed"}
      }
      expect(customisation.reload.name).to eq("Renamed")
    end
  end
end
