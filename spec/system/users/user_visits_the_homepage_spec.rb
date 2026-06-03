# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

# JS-only Selenium smoke tests for login flows.
# Non-interactive tests have been converted to spec/requests/pages_request_spec.rb.
RSpec.describe 'User visits the homepage', :default_creates, :js, :vcr, type: :system do
  include_context 'with api_data'
  include_context 'with wonde_test_data'

  context 'when logging in' do
    before do
      visit root_path
      student
    end

    it 'pops up the student login when needed' do
      click_button 'Login'
      expect(page).to have_text('Login').and have_text('Password')
    end

    it 'logs in a student using a username' do
      log_in_through_front_page(student.username, student.password)
      expect(page).to have_text(student.forename).and have_text(student.surname)
    end

    it 'logs in a teacher using an email' do
      log_in_through_front_page(teacher.username, teacher.password)
      expect(page).to have_text(teacher.forename).and have_text(teacher.surname)
    end

    it 'logs in using Google oAuth' do
      student = create(:student, oauth_uid: '123456123456')
      stub_google_omniauth
      click_button 'Login'
      find_by_id('loginGoogle').click
      expect(page).to have_text(student.forename).and have_text(student.surname)
    end
  end

  it 'displays log in error messages' do
    visit root_path
    stub_google_omniauth
    click_button 'Login'
    find_by_id('loginGoogle').click
    expect(page).to have_text('Your account has not been found')
  end
end
