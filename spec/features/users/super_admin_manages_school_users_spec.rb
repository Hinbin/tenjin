RSpec.describe 'School admin manages school users', type: :feature, js: true do
  include_context 'default_creates'

  before do
    sign_in create(:admin, role: 'super')
    school
    teacher
    visit(school_path(school))
    click_link 'Manage User Roles'
  end

  it 'allows an admin to upgrade the role of an employee' do
    select 'school_admin', from: ('role-select-user-' + teacher.id.to_s)
    visit(school_path(school))
    expect(page).to have_css('.school-admin-data', count: 1)
  end

  it 'only shows employees' do
    expect(page).to have_css('.employee-row', count: 1)
  end

  it 'allows me to log in as a school admin' do
    school_admin
    visit(school_path(school))
    click_button('Become User')
    expect(page).to have_content(school_admin.forename).and have_content(school_admin.surname)
  end

end
