# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::Schools", :default_creates, type: :request do
  let(:school_group_admin) { create(:school_group_admin) }

  describe "GET /system/schools" do
    before { sign_in super_admin }

    it "renders the index" do
      get system_schools_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /system/schools/stats" do
    before { sign_in super_admin }

    it "renders overall_statistics for super admins" do
      get stats_system_schools_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /system/schools/:id" do
    before do
      sign_in admin
      get system_school_path(school)
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "links to role management for the school" do
        expect(response.body).to include(manage_roles_system_users_path(school: school))
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it "does not link to role management" do
        expect(response.body).not_to include(manage_roles_system_users_path(school: school))
      end
    end
  end

  describe "PATCH /system/schools/:id/sync" do
    before { sign_in super_admin }

    it "queues a sync as admin" do
      patch sync_system_school_path(school)
      expect(response).to have_http_status(:no_content)
      expect(school.reload.sync_status).to eq("queued")
    end
  end
end

RSpec.describe "Schools (user-side)", :default_creates, type: :request do
  describe "PATCH /schools/:id/sync" do
    it "queues a sync as school_admin User" do
      sign_in school_admin
      patch sync_school_path(school)
      expect(response).to have_http_status(:no_content)
      expect(school.reload.sync_status).to eq("queued")
    end
  end
end
