RSpec.describe 'Super manages a school', type: :feature, js: true, default_creates: true do
  before do
    sign_in super_admin
  end

  context 'when becoming a school admin' do
    before do
      school_admin
    end

    it 'allows you to become a school admin' do
      visit school_path(school)
      click_button 'Become User'
      expect(page).to have_content(school_admin.forename)
    end
  end

  context 'when assigning school admins to a school' do
    before do
      teacher
      school_admin
    end

    it 'changes an employee to a school admin' do
      visit school_path(school)
      click_link 'Manage User Roles'
      select 'school_admin', from: "role-select-user-#{teacher.id}"
      visit school_path(school)
      expect(page).to have_content(teacher.username)
    end

    it 'removes school admins' do
      visit show_employees_school_path(school)
      select 'employee', from: "role-select-user-#{school_admin.id}"
      visit school_path(school)
      expect(page).to have_no_content(school_admin.username)
    end
  end
end
