# frozen_string_literal: true

RSpec.describe 'Super manages user roles', type: :system, js: true, default_creates: true do
  before do
    sign_in super_admin
    school
    subject
    teacher
    visit(manage_roles_users_path(school: teacher.school))
  end

  it 'adds a school admin role' do
    select 'school_admin', from: 'user[role]'
    click_button('Add Role')
    within('#school_admin-table') { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
  end

  it 'removes a school admin role' do
    teacher.add_role :school_admin
    visit(manage_roles_users_path(school: teacher.school))
    click_button('Remove')
    expect(page).to have_no_css('#school_admin-table')
  end

  it 'adds a question author role' do
    select subject.name, from: 'user[subject]'
    select 'question_author', from: 'user[role]'
    click_button('Add Role')
    within('#question_author-table') { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
  end

  it 'removes a question author role' do
    teacher.add_role :question_author, subject
    visit(manage_roles_users_path(school: teacher.school))
    click_button('Remove')
    expect(page).to have_no_css('#question_author-table')
  end

  it 'adds a lesson author role' do
    select subject.name, from: 'user[subject]'
    select 'lesson_author', from: 'user[role]'
    click_button('Add Role')
    within('#lesson_author-table') { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
  end

  it 'removes a lesson author role' do
    teacher.add_role :lesson_author, subject
    visit(manage_roles_users_path(school: teacher.school))
    click_button('Remove')
    expect(page).to have_no_css('#lesson_author-table')
  end

  it 'shows employees' do
    visit(school_path(school))
    click_link 'Manage User Roles'
    expect(page).to have_css('.employee-row', count: 1)
  end
end
