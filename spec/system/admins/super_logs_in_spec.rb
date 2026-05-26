# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super logs in", :default_creates, :js do
  before { visit(new_admin_session_path) }

  it "authenticates with email and password" do
    fill_in "Email", with: super_admin.email
    fill_in "Password", with: super_admin.password
    click_button "Log in"
    expect(page).to have_content("Schools")
  end

  it "does not authenticate with invalid credentials" # pending — counterpart for successful login
end
