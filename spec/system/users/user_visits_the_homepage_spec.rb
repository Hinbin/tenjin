# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

# JS-only Selenium smoke tests for login flows.
# Non-interactive tests have been converted to spec/requests/pages_request_spec.rb.
RSpec.describe 'User visits the homepage', :vcr, type: :system, js: true, default_creates: true do
  include_context 'with api_data'
  include_context 'with wonde_test_data'

  context 'when logging in' do
    before do
      visit root_path
      student
    end

    it 'pops up the student login when needed' do
      click_button 'Login'
      expect(page).to have_content('Login').and have_content('Password')
    end

    it 'logs in a student using a username' do
      log_in_through_front_page(student.username, student.password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end

    it 'logs in a teacher using an email' do
      log_in_through_front_page(teacher.username, teacher.password)
      expect(page).to have_content(teacher.forename).and have_content(teacher.surname)
    end

    it 'logs in using Google oAuth' do
      student = create(:student, oauth_uid: '123456123456')
      stub_google_omniauth
      click_button 'Login'
      find(:css, '#loginGoogle').click
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end

  it 'displays log in error messages' do
    visit root_path
    stub_google_omniauth
    click_button 'Login'
    find(:css, '#loginGoogle').click
    expect(page).to have_text('Your account has not been found')
  end
end
