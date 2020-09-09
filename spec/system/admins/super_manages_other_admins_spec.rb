# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Super manages other admins', type: :system, js: true, default_creates: true do

  before do
    sign_in super_admin
  end

  it 'allows me to create a school group account'
  it 'allows me to invite an admin to confirm their account'
  it 'allows me to set an admin as a school group admin'
end
