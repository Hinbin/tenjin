# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Super resets year data', :default_creates, :js, type: :system do
  it 'resets year data' do
    sign_in super_admin
    visit admin_path(super_admin)
    click_link 'Reset Year Data'
    page.accept_confirm
    expect(page).to have_text('Reset Year Data')
  end

  it 'prevents students from accessing the page' do
    super_admin
    sign_in students
    visit admin_path(super_admin)
    expect(page).to have_no_text('Reset Year Data')
  end

  it 'only allows super admins to access the page' do
    super_admin
    sign_in admin
    visit admin_path(super_admin)
    expect(page).to have_no_text('Reset Year Data')
  end
end
