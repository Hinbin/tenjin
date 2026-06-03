# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages', :default_creates, type: :request do
  context 'when looking at the home page' do
    before { get root_path }

    it 'has a Login button' do
      expect(response.body).to include('Login')
    end

    it 'has TENJIN content' do
      expect(response.body).to include('TENJIN')
    end

    it 'has an About link' do
      expect(response.body).to include('About')
    end

    it 'has a fixed top nav bar' do
      html = Capybara.string(response.body)
      expect(html).to have_css('nav.fixed-top')
    end
  end

  it 'redirects to dashboard if already signed in' do
    sign_in student
    get root_path
    expect(response).to redirect_to(dashboard_path)
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

    it 'does not have a fixed top nav bar on the about page' do
      html = Capybara.string(response.body)
      expect(html).to have_no_css('nav.fixed-top')
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
    it 'displays a message to click on the users name' do
      sign_in create(:student, :no_oauth)
      get dashboard_path
      expect(response.body).to include("Let's get your account linked")
    end

    it 'only displays the message when the account is not yet linked to Google' do
      sign_in student
      get dashboard_path
      expect(response.body).not_to include("Let's get your account linked")
    end

    it 'displays the message for teachers' do
      sign_in create(:teacher, :no_oauth)
      get dashboard_path
      expect(response.body).to include("Let's get your account linked")
    end
  end
end
