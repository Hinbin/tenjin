# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teacher visits the dashboard", :default_creates, :js do
  let(:classroom) { create(:classroom, subject: quiz_subject, school: teacher.school) }

  before do
    setup_subject_database
  end

  describe "as a teacher" do
    before do
      create(:enrollment, classroom: classroom, user: teacher)
      sign_in teacher
      visit(dashboard_path)
    end

    it "shows assigned classrooms" do
      expect(page).to have_content(classroom.name)
    end

    it "navigates to a selected classroom" do
      click_link(classroom.name)
      expect(page).to have_current_path(classroom_path(classroom))
    end

    it "navigates to the set homework form" do
      click_link("Set Homework")
      expect(page).to have_current_path(new_homework_path(classroom: {classroom_id: classroom.id}))
    end

    it "shows a link to the classrooms in the nav bar" do
      expect(page).to have_link("Classrooms", href: dashboard_path)
    end

    it "shows challenge points"

    it "does not show challenge points" do
      expect(page).to have_no_css("i.fa-star")
    end

    it "does not show other classrooms"

    context "when another teacher's classroom exists in the school" do
      let(:other_classroom) { create(:classroom, school: school) }
      let!(:other_enrollment) { create(:enrollment, classroom: other_classroom, user: create(:teacher, school: school)) }
      before { visit(dashboard_path) }

      it "shows the other classroom" do
        expect(page).to have_css("#otherClassrooms [data-classroom='#{other_classroom.id}']")
      end
    end
  end

  describe "as a school admin" do
    before do
      create(:enrollment, classroom: classroom, user: school_admin)
      sign_in school_admin
      visit(dashboard_path)
    end

    it "shows a link to the classrooms in the nav bar" do
      expect(page).to have_link("Classrooms", href: dashboard_path)
    end

    it "shows a link to school admin in the nav bar" do
      expect(page).to have_link("User Admin", href: users_path)
    end
  end
end
