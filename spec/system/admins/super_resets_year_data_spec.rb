# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super resets year data", :default_creates, :js do
  before do
    sign_in super_admin
    visit admin_path(super_admin)
  end

  it "flashes confirmation after triggering the reset" do
    page.accept_confirm { click_button "Reset Year Data" }
    expect(page).to have_css(".alert", text: "Reset Year Data")
  end
end
