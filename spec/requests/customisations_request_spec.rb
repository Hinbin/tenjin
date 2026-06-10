# frozen_string_literal: true

require "rails_helper"

RSpec.describe "customisations", :default_creates do
  let(:school_group_admin) { create(:school_group_admin) }

  describe "GET /customisations" do
    before do
      sign_in admin
      get customisations_path
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
      get customisations_path
    end

    it "redirects users to the admin login" do
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "admin navbar" do
    before do
      sign_in admin
      get schools_path
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "links to customisations" do
        expect(response.body).to include(customisations_path)
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it "does not link to customisations" do
        expect(response.body).not_to include(customisations_path)
      end
    end
  end

  describe "user navbar" do
    before do
      sign_in student
      get dashboard_path
    end

    it "links to the customisation shop from the challenge star and points" do
      expect(response.body).to include(show_available_customisations_path)
    end
  end

  describe "POST /customisations/:id/buy" do
    before { sign_in student }

    context "with a non-existent customisation id" do
      it "redirects to the dashboard" do
        post buy_customisation_path(id: rand(200..300))
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
