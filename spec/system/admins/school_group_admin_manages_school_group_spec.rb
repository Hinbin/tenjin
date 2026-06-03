# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School group admin manages school group', type: :system, js: true, default_creates: true do
  before do
    school
    sign_in school_group_admin
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
end
