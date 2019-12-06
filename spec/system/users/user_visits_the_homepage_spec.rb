# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User visits the homepage', :vcr, type: :system, js: true do
  include_context 'api_data'
  include_context 'wonde_test_data'
  include_context 'default_creates'

  context 'when looking at the page' do
    subject { page }

    before { visit root_path }

    it { is_expected.to have_button('Login') }
    it { is_expected.to have_content('TENJIN') }
    it { is_expected.to have_link('About') }
  end

  context 'when logging in' do
    let(:student_google) { create(:student, :oauth, oauth_uid: '123456123456') }

    before do
      visit root_path
      student
    end

    it 'pops up the student login when needed' do
      click_button 'Login'
      expect(page).to have_content('Login').and have_content('Password')
    end

    it 'logs in a student using an username' do
      log_in_through_front_page(student.username, student.password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end

    it 'logs in a teacher using an email' do
      log_in_through_front_page(teacher.username, teacher.password)
      expect(page).to have_content(teacher.forename).and have_content(teacher.surname)
    end

    it 'logs in using Google oAuth' do
      student_google
      stub_google_omniauth
      click_button 'Login'
      find(:css, '#loginGoogle').click
      expect(page).to have_content(student_google.forename).and have_content(student_google.surname)
    end

    it 'redirects to dashboard if they are already signed in' do
      sign_in student
      visit('/')
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end

  it 'has a fixed top nav bar on the home page' do
    visit root_path
    expect(page).to have_css('nav.fixed-top')
  end

  it 'displays log in error messages', :focus do
    visit root_path
    stub_google_omniauth
    click_button 'Login'
    find(:css, '#loginGoogle').click
    expect(page).to have_text('Your account has not been found')
  end

  context 'when looking at the about page' do
    before do
      hide_const('OGAT')
      visit page_path('about')
    end

    it 'shows the about page' do
      visit page_path('about')
      expect(page).to have_css('#standardAbout')
    end

    it 'does not have a fixed top nav bar on the about page' do
      visit page_path('about')
      expect(page).to have_no_css('nav.fixed-top')
    end
  end

  context 'with the OGAT environment variable set' do
    before do
      stub_const('ENV', 'OGAT' => 'true')
    end

    it 'shows the OGAT about page if the correct ENV is set' do
      visit page_path('about')
      expect(page).to have_css('#ogatAbout')
    end
  end
end
