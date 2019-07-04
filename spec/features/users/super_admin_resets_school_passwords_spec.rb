RSpec.describe 'School admin views student list', :focus, type: :feature, js: true do
  include_context 'default_creates'

  before do
    sign_in create(:admin, role: 'super')
    school
    create_list(:student, 5, school: school)
    create_list(:teacher, 2, school: school)
  end

  it 'allows an admin to produce a table to email to a school' do
    visit(school_path(school))
    click_button 'Reset All Passwords'
    page.accept_alert
    find('.student-row:first-child')
    expect(page).to have_css('.student-row', count: 7).and have_content('CSV')
  end

  it 'allows an admin to reset the password for an individual'
end
