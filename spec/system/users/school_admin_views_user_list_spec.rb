# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin views user list", :default_creates, :js do
  before do
    setup_subject_database
  end

  describe "as a teacher" do
    before do
      sign_in teacher
      visit(users_path)
    end

    it "is not authorized to view the page" do
      expect(page).to have_text("You are not authorized to perform this action.")
    end
  end

  describe "as a student" do
    before do
      sign_in student
      visit(users_path)
    end

    it "is not authorized to view the page" do
      expect(page).to have_text("You are not authorized to perform this action.")
    end
  end

  describe "as a school admin" do
    before do
      sign_in school_admin
      visit(users_path)
    end

    it "warns that resetting all passwords cannot be undone" do
      find_by_id("resetPrintModalButton").click
      expect(page).to have_text("This action cannot be undone.")
    end

    it "does not enable the confirmation button until the school name matches" do
      find_by_id("resetPrintModalButton").click
      find_by_id("confirmAllPasswordResetTextbox").set("test")
      expect(page).to have_link("Confirm", class: "disabled")
    end

    it "enables the confirmation button when the school name is entered" do
      click_button("Reset and print all passwords")
      find_by_id("confirmAllPasswordResetTextbox").set(school.name)
      expect(page).to have_link("Confirm")
    end

    it "resets all passwords and presents a download link" do
      click_button("Reset and print all passwords")
      find_by_id("confirmAllPasswordResetTextbox").set(school.name)
      click_link("Confirm")
      expect(page).to have_content("Password").and have_content("CSV")
    end

    context "with students enrolled in the school" do
      before do
        create(:enrollment, classroom: classroom, user: teacher)
        create_list(:enrollment, 5, classroom: classroom, school: school)
        visit(users_path)
      end

      it "shows students belonging to the school" do
        expect(page).to have_text(school.users.find_by!(role: "student").surname)
      end
    end

    context "with students from another school" do
      let!(:other_enrollment) { create(:enrollment, school: second_school) }

      before { visit(users_path) }

      it "does not show students from another school" do
        expect(page).to have_no_text(second_school.users.find_by!(role: "student").surname)
      end
    end

    context "with more than one page of students" do
      before do
        create_list(:enrollment, 32, classroom: classroom)
        visit(users_path)
      end

      it "filters students by name" do
        find("#students-table_filter input").set("#{student.forename} #{student.surname}")
        expect(page).to have_css(".student-row", count: 1).and have_content("#{student.forename} #{student.surname}")
      end
    end

    context "with 100 enrolled students" do
      before do
        create_list(:enrollment, 100, classroom: classroom)
        visit(users_path)
      end

      it "paginates the student table" do
        expect(page).to have_css(".student-row", count: 10)
      end
    end

    context "with an additional teacher" do
      before do
        create(:teacher, school: school)
        visit(users_path)
      end

      it "shows all employees for the school" do
        expect(page).to have_css(".employee-row", count: 2)
      end
    end

    context "with an additional school admin" do
      before do
        create(:school_admin, school: school)
        visit(users_path)
      end

      it "shows school admins in the employee list" do
        expect(page).to have_css(".employee-row", count: 2)
      end
    end

    it "resets a student password and shows the new password" do
      within "#students-table" do
        click_link("Reset Password")
        expect(page).to have_no_link("Reset Password").and have_css(".new-password")
      end
    end

    it "resets an employee password and shows the new password" do
      within "#employees-table" do
        click_link("Reset Password")
        expect(page).to have_no_link("Reset Password").and have_css(".new-password")
      end
    end
  end
end
