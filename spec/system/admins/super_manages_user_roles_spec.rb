# frozen_string_literal: true

RSpec.describe 'Super manages school users', type: :system, js: true, default_creates: true do
  before do
    sign_in create(:admin, role: 'super')
    school
  end

  context 'when managing employees' do
    before do
      teacher
    end

    it 'shows employees' do
      visit(school_path(school))
      click_link 'Manage User Roles'
      expect(page).to have_css('.employee-row', count: 1)
    end

    it 'allows me to log in as a school admin' do
      school_admin
      visit(school_path(school))
      within('#schoolAdminTable') { click_button('Become User')}
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
