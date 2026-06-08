# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super resets year data", :default_creates, :js do
  it "resets year data" do
    sign_in super_admin
    visit admin_path(super_admin)
    page.accept_confirm { click_button "Reset Year Data" }
    expect(page).to have_button("Reset Year Data")
  end

  it "prevents students from accessing the page" do
    sign_in student
    visit admin_path(super_admin)
    expect(page).to have_no_button("Reset Year Data")
  end

  it "only allows super admins to access the page" do
    sign_in school_group_admin
    visit admin_path(super_admin)
    expect(page).to have_no_button("Reset Year Data")
  end
end
