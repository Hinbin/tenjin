# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin views a student record", :default_creates, :js do
  let(:new_password) { FFaker::Internet.password }

  describe "as a school admin" do
    before do
      sign_in school_admin
      visit(user_path(student))
    end

    it "shows the password reset option" do
      expect(page).to have_button("Update Password")
    end

    it "updates the user password" do
      update_password(new_password)
      expect(page).to have_text("Password successfully updated")
      sign_out school_admin
      log_in_through_front_page(student.username, new_password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end
  end

  describe "as a teacher" do
    before do
      sign_in teacher
      visit(user_path(student))
    end

    it "shows the password reset option" do
      expect(page).to have_button("Update Password")
    end
  end

  describe "as a student viewing their own record" do
    before do
      sign_in student
      visit(user_path(student))
    end

    it "shows the password reset option" do
      expect(page).to have_button("Update Password")
    end
  end
end
