require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User visits the home page', :vcr, type: :feature, js: true do
  include_context 'api_data'
  include_context 'wonde_test_data'

  context 'when looking at the page' do
    subject { page }

    before { visit root_path }

    it { is_expected.to have_link('Log In') }
    it { is_expected.to have_content('TENJIN') }
    it { is_expected.to have_content('SUCCEED') }
  end

  it 'logs me in' do
    log_in
    expect(page).to have_content('Leo Ward')
  end

  it 'redirects to dashboard if they are already signed in' do
    log_in
    visit('/')
    expect(page).to have_content('START A QUIZ')
  end
end
