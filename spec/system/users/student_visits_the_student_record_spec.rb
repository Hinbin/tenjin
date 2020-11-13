# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User visits the homepage', :vcr, default_creates: true, type: :system, js: true do
  let(:student) { create(:student) }
  let(:new_password) { FFaker::Lorem.word }

  before do
    sign_in student
    stub_google_omniauth
  end

  def log_in_via_google
    sign_out student
    visit root_path
    click_button 'Login'
    find('#loginGoogle').click
    find('.alert', text: 'authenticated')
  end

  it 'change passwords' do
    visit(user_path(student))
    fill_in('user[password]', with: new_password)
    click_button('Update Password')
    log_in_through_front_page(student.username, new_password)
    expect(page).to have_content(student.forename).and have_content(student.surname)
  end

  it 'unlinks Google accounts' do
    visit(user_path(student))
    page.accept_confirm { click_link "Unlink #{student.oauth_email}" }
    expect(page).to have_css('#loginGoogle')
  end

  context 'when linking Google accounts' do
    let(:student_no_oauth) { create(:student, :no_oauth) }

    before do
      sign_in student_no_oauth
      stub_google_omniauth
    end

    it 'links to Google accounts' do
      visit(user_path(student_no_oauth))
      find(:css, '#loginGoogle').click
      find('.alert', text: 'linked')
      log_in_via_google
      expect(page).to have_content(student_no_oauth.forename).and have_content(student_no_oauth.surname)
    end

    it 'shows an appropriate flash message when linking accounts' do
      visit(user_path(student_no_oauth))
      find('.shepherd-text')
      find(:css, '#loginGoogle').click
      expect(page).to have_content('Successfully linked Google account')
    end
  end
end
