# frozen_string_literal: true

RSpec.describe 'Super manages user roles', type: :system, js: true, default_creates: true do
  before do
    sign_in create(:admin, role: 'super')
    school
  end

  context 'when managing employees' do
    before do
      teacher
      subject
      visit(manage_roles_users_path(school: teacher.school))
    end

    it 'adds a school admin role' do
      select 'school_admin', from: 'user[role]'
      click_button('Add Role')
      within('#school_admin-table') { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
    end

    it 'adds a question author role' do
      select subject.name, from: 'user[subject]'
      select 'question_author', from: 'user[role]'
      click_button('Add Role')
      within('#question_author-table') { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
    end

    it 'removes a question author role' do
      select subject.name, from: 'user[subject]'
      select 'question_author', from: 'user[role]'
      click_button('Add Role')
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
      select subject.name, from: 'user[subject]'
      select 'lesson_author', from: 'user[role]'
      click_button('Add Role')
      click_button('Remove')
      expect(page).to have_no_css('#lesson_author-table')
    end

    it 'shows employees' do
      visit(school_path(school))
      click_link 'Manage User Roles'
      expect(page).to have_css('.employee-row', count: 1)
    end

    it 'allows me to log in as a school admin' do
      school_admin
      visit(school_path(school))
      within('#schoolAdminTable') { click_button('Become User') }
      expect(page).to have_content(school_admin.forename).and have_content(school_admin.surname)
    end
  end

  context 'when managing users' do
    before do
      student
      visit(school_path(school))
    end

    it 'allows me to log in as a user' do
      click_button('Become User')
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end
end
