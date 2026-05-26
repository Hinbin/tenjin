# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super manages other admins", :default_creates, :js do
  before do
    sign_in super_admin
  end

  it "creates a school group account"
  it "invites an admin to confirm their account"
  it "sets an admin as a school group admin"
end
