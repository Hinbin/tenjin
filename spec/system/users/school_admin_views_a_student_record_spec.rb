# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for school admin viewing student record.
# Non-interactive tests have been converted to spec/requests/users_controller_spec.rb.
RSpec.describe 'School admin views a student record', :default_creates, :js, type: :system do
  before do
    setup_subject_database
    sign_in school_admin
    visit(user_path(student))
  end

  it 'updates the user password' do
    update_password(new_password)
    sign_out school_admin
    log_in_through_front_page(student.username, new_password)
    expect(page).to have_text(student.forename).and have_text(student.surname)
  end
end
