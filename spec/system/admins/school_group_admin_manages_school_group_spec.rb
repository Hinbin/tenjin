# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School group admin manages school group', type: :system, js: true, default_creates: true do
  let(:school_group_admin) { create(:school_group_admin) }

  before do
    school
    sign_in school_group_admin
  end

  it 'allows me to see all schools' do
    visit(schools_path)
    expect(page).to have_content(school.name)
  end

  it 'allows me to see a single school' do
    visit(school_path(school))
    expect(page).to have_content(school.name)
  end

  it 'hides the manage role button' do
    visit(school_path(school))
    expect(page).to have_no_content('Manage User Roles')
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

  it 'allows me to see subject statistics' do
    visit subjects_path
    expect(page).to have_content('Questions Asked')
  end

  it 'hides the add school button' do
    visit schools_path
    expect(page).to have_no_content('Add School')
  end

  it 'shows the schools menu option' do
    visit schools_path
    expect(page).to have_css('.nav-link', text: 'Schools')
  end

  it 'hides school groups menu option' do
    visit schools_path
    expect(page).to have_no_css('.nav-link', text: 'School Groups')
  end

  it 'hides add subject button' do
    visit subjects_path
    expect(page).to have_no_content('Add Subject')
  end

  it 'hides the roles menu option' do
    visit schools_path
    expect(page).to have_no_css('.nav-link', text: 'Roles')
  end

end
