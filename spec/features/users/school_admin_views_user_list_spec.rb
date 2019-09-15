RSpec.describe 'School admin views user list', type: :feature, js: true, default_creates: true do

  before do
    setup_subject_database
    sign_in school_admin
  end

  it 'does not allow a teacher to view the page' do
    sign_out school_admin
    sign_in teacher
    visit(users_path)
    expect(page).to have_text('You are not authorized to perform this action.')
  end

  it 'does not allow a student to view the page' do
    sign_out school_admin
    sign_in student
    visit(users_path)
    expect(page).to have_text('You are not authorized to perform this action.')
  end

  it 'gives a clear warning when an admin resets all passwords that this is dangerous' do
    visit(users_path)
    find('#resetPrintModalButton').click
    expect(page).to have_text('This action cannot be undone.')
  end

  it 'enables the reset all password confirmation button with the school name' do
    visit(users_path)
    find('#resetPrintModalButton').click
    find('#confirmAllPasswordResetTextbox').set('test')
    expect(page).to have_link('Confirm', class: 'disabled')
  end

  it 'makes a user type in their school name to reset all usernames' do
    visit(users_path)
    click_button('Reset and print all passwords')
    find('#confirmAllPasswordResetTextbox').set(school.name)
    expect(page).to have_link('Confirm')
  end

  it 'allows an admin to reset all passwords and save a list of username and passwords'do
    visit(users_path)
    click_button('Reset and print all passwords')
    find('#confirmAllPasswordResetTextbox').set(school.name)
    click_link('Confirm')
    expect(page).to have_content('Password').and have_content('CSV')
  end

  it 'shows a list of students belonging to the school' do
    create(:enrollment, classroom: classroom, user: teacher)
    create_list(:enrollment, 5, classroom: classroom, school: school)
    visit(users_path)
    expect(page).to have_text(User.where(role: 'student', school: school).first.surname)
  end

  it 'does not shows students that belong to another school' do
    create(:enrollment, school: second_school)
    visit(users_path)
    expect(page).to have_no_text(User.where(role: 'student', school: second_school).first.surname)
  end

  it 'allows you to search for a student' do
    create_list(:enrollment, 32, classroom: classroom)
    visit(users_path)
    find('#students-table_filter input').set("#{student.forename} #{student.surname}")
    expect(page).to have_css('.student-row', count: 1).and have_content("#{student.forename} #{student.surname}")
  end

  it 'paginates the student table' do
    create_list(:enrollment, 100, classroom: classroom)
    visit(users_path)
    expect(page).to have_css('.student-row', count: 10)
  end

  it 'shows employees if I am a school admin' do
    create(:teacher, school: school)
    visit(users_path)
    expect(page).to have_css('.employee-row', count: 2)
  end

  it 'shows other school admins if I am a school admin' do
    create(:school_admin, school: school)
    visit(users_path)
    expect(page).to have_css('.employee-row', count: 2)
  end

  it 'resets a password and then shows the result' do
    visit(users_path)
    within '#students-table' do
      click_link('Reset Password')
      expect(page).to have_no_link('Reset Password').and have_css('.new-password')
    end
  end

  it 'does not show employees if I am an employee'

  it 'lets me reset passwords for employees if I am a school admin'
end
