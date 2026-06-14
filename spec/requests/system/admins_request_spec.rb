# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Admins", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/admins/:id" do
    it "renders the admin show page" do
      get system_admin_path(super_admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /system/admins/:id/become" do
    let!(:target) { create(:student, school: school) }

    it "signs in as the target user and redirects to root" do
      post become_system_admin_path(super_admin, user_id: target.id)
      expect(response).to redirect_to(root_url)
    end
  end

  describe "POST /system/admins/:id/reset_year" do
    it "schedules ResetYearJob" do
      expect {
        post reset_year_system_admin_path(super_admin)
      }.to have_enqueued_job(ResetYearJob)
    end

    it "redirects to system_schools_path" do
      post reset_year_system_admin_path(super_admin)
      expect(response).to redirect_to(system_schools_path)
    end
  end
end
