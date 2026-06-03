# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for school admin user list interactions.
# Non-interactive tests have been converted to spec/requests/users_controller_spec.rb.
RSpec.describe 'School admin views user list', :default_creates, :js, type: :system do
  before do
    setup_subject_database
    sign_in school_admin
  end

  it 'gives a clear warning when an admin resets all passwords that this is dangerous' do
    visit(users_path)
    find_by_id('resetPrintModalButton').click
    expect(page).to have_text('This action cannot be undone.')
  end

  it 'enables the reset all password confirmation button with the school name' do
    visit(users_path)
    find_by_id('resetPrintModalButton').click
    find_by_id('confirmAllPasswordResetTextbox').set('test')
    expect(page).to have_link('Confirm', class: 'disabled')
  end

  it 'makes a user type in their school name to reset all usernames' do
    visit(users_path)
    click_button('Reset and print all passwords')
    find_by_id('confirmAllPasswordResetTextbox').set(school.name)
    expect(page).to have_link('Confirm')
  end

  it 'allows an admin to reset all passwords and save a list of username and passwords' do
    visit(users_path)
    click_button('Reset and print all passwords')
    find_by_id('confirmAllPasswordResetTextbox').set(school.name)
    click_link('Confirm')
    expect(page).to have_text('Password').and have_text('CSV')
  end

  it 'allows you to search for a student' do
    create_list(:enrollment, 32, classroom:)
    visit(users_path)
    find('#students-table_filter input').set("#{student.forename} #{student.surname}")
    expect(page).to have_css('.student-row', count: 1).and have_text("#{student.forename} #{student.surname}")
  end

  it 'paginates the student table' do
    create_list(:enrollment, 100, classroom:)
    visit(users_path)
    expect(page).to have_css('.student-row', count: 10)
  end

  it 'resets a student password and then shows the result' do
    visit(users_path)
    within '#students-table' do
      click_link('Reset Password')
      expect(page).to have_no_link('Reset Password').and have_css('.new-password')
    end
  end

  it 'resets an employee password and then shows the result' do
    visit(users_path)
    within '#employees-table' do
      click_link('Reset Password')
      expect(page).to have_no_link('Reset Password').and have_css('.new-password')
    end
  end
end
