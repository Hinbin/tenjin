RSpec.describe 'School admin manages school employees', :focus, type: :feature, js: true do
  include_context 'default_creates'

  before do
    sign_in create(:admin, role: 'super')
    school
    create_list(:student, 5, school: school)
    teacher
    visit(school_path(school))
    click_button 'Manage Users'
  end

  it 'allows an admin to upgrade the role of an employee' do
    select 'School Administrator', from: ('employee-' + teacher.id)
    page.accept_alert
    expect(page).to have_css('.student-row', count: 7).and have_content('CSV')
  end

  it 'only shows employees' do
    expect(page).to have_css('.employee-row', count: 1)
  end

end
