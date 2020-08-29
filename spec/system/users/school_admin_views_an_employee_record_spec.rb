# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School admin views a teacher record', type: :system, js: true, default_creates: true do
  let(:new_password) { FFaker::Internet.password }

  before do
    setup_subject_database
  end

  context 'when updating the user password' do
    before do
      sign_in school_admin
      visit(user_path(teacher))
    end

    it 'shows the user password reset option for a school_admin' do
      expect(page).to have_button('Update Password')
    end

    it 'updates the user password' do
      update_password(new_password)
      sign_out school_admin
      log_in_through_front_page(teacher.username, new_password)
      expect(page).to have_content(teacher.forename).and have_content(teacher.surname)
    end
  end

  it 'shows the user password reset option for an employee' do
    sign_in teacher
    visit(user_path(teacher))
    expect(page).to have_button('Update Password')
  end
end
