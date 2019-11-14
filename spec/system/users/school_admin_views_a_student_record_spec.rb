# frozen_string_literal: true

RSpec.describe 'School admin views a student record', type: :system, js: true, default_creates: true do
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
      update_password(new_password)
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

  it 'show the user password reset option for a student for their account' do
    sign_in student
    visit(user_path(student))
    expect(page).to have_button('Update Password')
  end
end
