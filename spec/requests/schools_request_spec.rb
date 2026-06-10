# frozen_string_literal: true

require "rails_helper"

RSpec.describe "schools controller", :default_creates do
  let(:school_group_admin) { create(:school_group_admin) }

  describe "GET /schools/:id" do
    before do
      sign_in admin
      get school_path(school)
    end

    context "as a super admin" do
      let(:admin) { super_admin }

      it "links to role management for the school" do
        expect(response.body).to include(manage_roles_users_path(school: school))
      end
    end

    context "as a school group admin" do
      let(:admin) { school_group_admin }

      it "does not link to role management" do
        expect(response.body).not_to include(manage_roles_users_path(school: school))
      end
    end
  end
end
