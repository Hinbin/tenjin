# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super resets year data", :default_creates, :js do
  describe "as a super admin" do
    before do
      sign_in super_admin
      visit admin_path(super_admin)
    end

    it "resets year data" do
      page.accept_confirm { click_button "Reset Year Data" }
      within(".alert") { expect(page).to have_text("Reset Year Data") }
    end
  end

  describe "as a student" do
    before do
      sign_in student
      visit admin_path(super_admin)
    end

    it "cannot reset year data" do
      expect(page).to have_no_button("Reset Year Data")
    end
  end

  describe "as a school group admin" do
    before do
      sign_in school_group_admin
      visit admin_path(super_admin)
    end

    it "cannot reset year data" do
      expect(page).to have_no_button("Reset Year Data")
    end
  end
end
