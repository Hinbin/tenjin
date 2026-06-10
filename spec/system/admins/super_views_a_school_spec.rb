# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super views a school", :default_creates, :js do
  before { sign_in super_admin }

  describe "managing school admin emails" do
    let!(:school_admin) { create(:school_admin, school: school) }
    let(:new_email) { FFaker::Internet.email }

    before { visit(school_path(school)) }

    it "flashes a confirmation when an email is saved" do
      fill_in "user-email-#{school_admin.id}", with: new_email
      find("#save-email-#{school_admin.id}").click
      expect(page).to have_css(".alert-info",
        text: "Updated email to #{school_admin.forename} #{school_admin.surname}")
    end

    it "flashes a confirmation when a setup email is sent" do
      click_button "Send Setup Email"
      expect(page).to have_css(".alert-info",
        text: "Setup email sent to #{school_admin.forename} #{school_admin.surname}")
    end
  end
end
