require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User visits the home page', :vcr, type: :feature, js: true do
  include_context 'api_data'
  include_context 'wonde_test_data'

  context 'when looking at the page' do
    subject { page }

    before { visit root_path }

    it { is_expected.to have_link('Login') }
    it { is_expected.to have_content('TENJIN') }
  end

  context 'when logging in' do
    before do
      stub_omniauth
      visit root_path
      student_wonde
      click_link 'Login'
    end

    it 'logs me in' do
      expect(page).to have_content('Leo Ward')
    end

    it 'redirects to dashboard if they are already signed in' do
      page.has_content?('Leo Ward')
      visit('/')
      expect(page).to have_content('START A QUIZ')
    end
  end

  it 'displays log in error messages' do
    visit root_path
    stub_omniauth
    click_link 'Login'
    expect(page).to have_text('Your account has not been found')
  end
end
