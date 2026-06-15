# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin views user list", :default_creates, :js do
  let!(:student_enrollment) { create(:enrollment, user: student, classroom: classroom) }

  before do
    sign_in school_admin
    visit(users_path)
  end

  describe "resetting all passwords" do
    it "warns the action cannot be undone" do
      find_by_id("resetPrintModalButton").click
      expect(page).to have_text("This action cannot be undone.")
    end

    it "leaves the confirm button disabled until the school name matches" do
      find_by_id("resetPrintModalButton").click
      find_by_id("confirmAllPasswordResetTextbox").set("test")
      expect(page).to have_button("Confirm", class: "disabled")
    end

    it "enables the confirm button when the school name matches" do
      click_button("Reset and print all passwords")
      find_by_id("confirmAllPasswordResetTextbox").set(school.name)
      expect(page).to have_button("Confirm")
    end

    it "presents a CSV download link after confirming" do
      click_button("Reset and print all passwords")
      find_by_id("confirmAllPasswordResetTextbox").set(school.name)
      click_button("Confirm")
      expect(page).to have_content("Password").and have_content("CSV")
    end
  end

  describe "resetting a single password" do
    it "replaces the student's Reset Password link with the new password" do
      within "#students-table" do
        click_link("Reset Password")
        expect(page).to have_no_link("Reset Password").and have_css(".new-password")
      end
    end

    it "replaces the employee's Reset Password link with the new password" do
      within "#employees-table" do
        click_link("Reset Password")
        expect(page).to have_no_link("Reset Password").and have_css(".new-password")
      end
    end
  end

  describe "the student table" do
    it "shows students belonging to the school" do
      expect(page).to have_content(student.surname)
    end

    context "with students from another school" do
      let(:second_school) { create(:school, school_group: school.school_group) }
      let!(:other_enrollment) { create(:enrollment, school: second_school) }

      before { visit(users_path) }

      it "hides students from other schools" do
        within "#students-table" do
          expect(page).to have_no_content(other_enrollment.user.username)
        end
      end
    end

    context "with more than one page of students" do
      before do
        create_list(:enrollment, 32, classroom: classroom)
        visit(users_path)
      end

      it "filters students by name" do
        find(".col.table-responsive:has(#students-table) [data-datatable-target='search']")
          .set("#{student.forename} #{student.surname}")
        expect(page).to have_css(".student-row", count: 1)
          .and have_content("#{student.forename} #{student.surname}")
      end
    end

    context "with 100 enrolled students" do
      before do
        create_list(:enrollment, 100, classroom: classroom)
        visit(users_path)
      end

      it "paginates to 10 rows per page" do
        expect(page).to have_css(".student-row", count: 10)
      end
    end
  end

  describe "the employee table" do
    context "with an additional teacher" do
      before do
        create(:teacher, school: school)
        visit(users_path)
      end

      it "lists both employees" do
        expect(page).to have_css(".employee-row", count: 2)
      end
    end

    context "with an additional school admin" do
      before do
        create(:school_admin, school: school)
        visit(users_path)
      end

      it "lists both employees" do
        expect(page).to have_css(".employee-row", count: 2)
      end
    end
  end
end
