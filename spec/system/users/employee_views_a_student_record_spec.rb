# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for employee viewing student record.
# Non-interactive tests have been converted to spec/requests/users_controller_spec.rb.
RSpec.describe 'Employee views a user record', :default_creates, :js, type: :system do
  context 'when resetting passwords' do
    before do
      sign_in teacher
      create(:enrollment, user: student, classroom:)
      create(:enrollment, user: teacher, classroom:)
    end

    it 'lets me reset a student password' do
      visit(user_path(student))
      update_password(new_password)
      sign_out teacher
      log_in_through_front_page(student.username, new_password)
      expect(page).to have_text(student.forename).and have_text(student.surname)
    end
  end
end
