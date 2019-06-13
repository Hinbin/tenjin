RSpec.describe 'School admin views a student record', type: :feature, js: true do
  include_context 'default_creates'

  let(:new_password) { FFaker::Internet.password }

  before do
    setup_subject_database
  end

  context 'when updating the user password' do
    before do
      sign_in school_admin
      visit(user_path(student))
    end

    it 'shows the user password reset option for a school_admin' do
      expect(page).to have_button('Update Password')
    end

    it 'updates the user password' do
      find('#user_password').set(new_password)
      click_button('Update Password')
      sign_out school_admin
      log_in_through_front_page(student.username, new_password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end

    it 'tells the user the password has been updated' do
      find('#user_password').set(new_password)
      click_button('Update Password')
      expect(page).to have_text('Password successfully updated')
    end
  end

  it 'shows the user password reset option for an employee' do
    sign_in teacher
    visit(user_path(student))
    expect(page).to have_button('Update Password')
  end

  it 'does not show the user passwsord reset option for a student' do
    sign_in student
    visit(user_path(student))
    expect(page).to have_no_button('Update Password')

  end
end
