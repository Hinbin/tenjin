# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Super logs in', type: :system, js: true, default_creates: true do
  context 'when logging in' do
    before do
      super_admin
    end

    it 'allows an admin to log in' do
      visit(new_admin_session_path)
      fill_in 'Email', with: super_admin.email
      fill_in 'Password', with: super_admin.password
      click_button 'Log in'
      expect(page).to have_content('Schools')
    end
  end
end
