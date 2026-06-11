# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages', :default_creates, type: :request do
  context 'when looking at the home page' do
    before { get root_path }

    it 'has a Login button' do
      expect(response.body).to include('Login')
    end

    it 'has Tenjin content' do
      html = Capybara.string(response.body)
      expect(html).to have_css('#branding-text', text: 'Tenjin')
    end

    it 'has an About link' do
      expect(response.body).to include('About')
    end

    it 'has a navbar' do
      html = Capybara.string(response.body)
      expect(html).to have_css('nav.tj-navbar')
    end
  end

  it 'renders the dashboard if already signed in' do
    sign_in student
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Start a Quiz')
  end

  context 'when looking at the about page' do
    before do
      hide_const('OGAT')
      get page_path('about')
    end

    it 'shows the about page' do
      html = Capybara.string(response.body)
      expect(html).to have_css('#standardAbout')
    end

    it 'has the logged out navigation on the about page' do
      html = Capybara.string(response.body)
      expect(html).to have_css('nav.tj-navbar')
    end
  end

  context 'with the OGAT environment variable set' do
    it 'shows the OGAT about page if the correct ENV is set' do
      stub_const('ENV', 'OGAT' => 'true')
      get page_path('about')
      html = Capybara.string(response.body)
      expect(html).to have_css('#ogatAbout')
    end
  end

  context 'when being prompted to sign in with google' do
    it 'renders the account linking prompt trigger for students' do
      sign_in create(:student, :no_oauth)
      get dashboard_path
      html = Capybara.string(response.body)
      expect(html).to have_css('input#oAuthEmail', visible: :all)
    end

    it 'only renders the account linking prompt trigger when the account is not yet linked to Google' do
      sign_in student
      get dashboard_path
      html = Capybara.string(response.body)
      expect(html).to have_no_css('input#oAuthEmail', visible: :all)
    end

    it 'renders the account linking prompt trigger for teachers' do
      sign_in create(:teacher, :no_oauth)
      get dashboard_path
      html = Capybara.string(response.body)
      expect(html).to have_css('input#oAuthEmail', visible: :all)
    end
  end
end
