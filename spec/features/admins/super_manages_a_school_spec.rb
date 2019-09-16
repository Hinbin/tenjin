RSpec.describe 'Super manages a school', type: :feature, js: true, default_creates: true do
  let(:admin_password) { FFaker::Lorem.word }

  before do
    super_admin
    super_admin.reset_password(admin_password, admin_password)
  end

  it 'allows an admin to log in' do
    visit(new_admin_session_path)
    fill_in 'Email', with: super_admin.email
    fill_in 'Password', with: admin_password
    click_button 'Log in'
    expect(page).to have_content('Schools')
  end

  context 'when becoming a school admin' do
    before do
      sign_in super_admin
      school_admin
    end

    it 'allows you to become a school admin' do
      visit school_path(school)
      click_button 'Become User'
      expect(page).to have_content(school_admin.forename)
    end
  end

  context 'when assigning school admins' do
    before do
      teacher
      school_admin
      sign_in super_admin
    end

    it 'takes you to the employees role management screen' do
      visit school_path(school)
      click_link('Manage User Roles')
      expect(page).to have_content('MANAGE ROLES')
    end

    it 'changes an employee to a school admin' do
      visit show_employees_school_path(school)
      select 'school_admin', from: "role-select-user-#{teacher.id}"
      expect(page).to have_content(teacher.username)
    end

    it 'removes school admins' do
      sign_in super_admin
      visit show_employees_school_path(school)
      select 'employee', from: "role-select-user-#{school_admin.id}"
      visit school_path(school)
      expect(page).to have_no_content(school_admin.username)
    end
  end
end
