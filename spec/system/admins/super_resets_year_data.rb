# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super resets year data", :default_creates, :js do
  it "resets year data" do
    sign_in super_admin
    visit admin_path(super_admin)
    click_link "Reset Year Data"
    page.accept_confirm
    expect(page).to have_content("Reset Year Data")
  end

  it "prevents students from accessing the page" do
    sign_in student
    visit admin_path(super_admin)
    expect(page).to have_no_content("Reset Year Data")
  end

  it "only allows super admins to access the page" do
    sign_in school_group_admin
    visit admin_path(super_admin)
    expect(page).to have_no_content("Reset Year Data")
  end
end
