# frozen_string_literal: true

RSpec.describe 'Super views a school', type: :system, js: true, default_creates: true do
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
    within('#schoolAdminTable') { click_button 'Become User' }
    expect(page).to have_css('#current_user', text: "#{school_admin.forename} #{school_admin.surname}")
  end

  it 'links to role management for that school' do
    visit(school_path(school))
    click_link 'Manage User Roles'
    expect(page).to have_current_path(manage_roles_users_path(school: school))
  end

end
