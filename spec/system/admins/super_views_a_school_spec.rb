# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Super views a school', type: :system, js: true, default_creates: true do
  let(:new_email) { FFaker::Internet.email }
  let(:email_notice) do
    "Setup email sent to #{school_admin.forename} #{school_admin.surname} (#{school_admin.email})"
  end

  before do
    sign_in super_admin
    school
  end

  it 'allows you to become a student' do
    student
    visit(school_path(school))
    click_button('Become User')
    expect(page).to have_css('#current_user', text: "#{student.forename} #{student.surname}")
  end

  it 'allows you to become a school admin' do
    school_admin
    visit school_path(school)
    within('#schoolAdminTable') { click_link 'Become User' }
    expect(page).to have_css('#current_user', text: "#{school_admin.forename} #{school_admin.surname}")
  end

  it 'saves email addresses of school admins' do
    school_admin
    visit(school_path(school))
    fill_in "user-email-#{school_admin.id}", with: new_email
    find("#save-email-#{school_admin.id}").click
    expect(page).to have_css('#flash-notice', text: "Updated email to #{new_email}")
  end

  it 'notifies users that a setup email has been sent' do
    school_admin
    visit(school_path(school))
    click_link 'Send Setup Email'
    expect(page).to have_css('#flash-notice', text: email_notice, wait: 6)
  end
end
