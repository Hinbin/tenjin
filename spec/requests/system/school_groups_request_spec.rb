# frozen_string_literal: true

require "rails_helper"

RSpec.describe "System::SchoolGroups", :default_creates, type: :request do
  before { sign_in super_admin }

  describe "GET /system/school_groups" do
    it "renders the index" do
      create(:school_group, name: "North")
      get system_school_groups_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("North")
    end
  end

  describe "POST /system/school_groups" do
    it "creates a school group" do
      expect {
        post system_school_groups_path, params: {school_group: {name: "East"}}
      }.to change(SchoolGroup, :count).by(1)
      expect(response).to redirect_to(system_school_groups_path)
    end
  end
end
