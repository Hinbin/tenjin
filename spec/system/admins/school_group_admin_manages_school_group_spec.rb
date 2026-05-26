# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School group admin manages school group", :default_creates, :js do
  let!(:school) { create(:school) }

  before { sign_in school_group_admin }

  describe "viewing schools" do
    before { visit(schools_path) }

    it "shows all schools" do
      expect(page).to have_content(school.name)
    end

    it "hides the add school button" do
      expect(page).to have_no_content("Add School")
    end

    it "shows the schools menu option" do
      expect(page).to have_css(".nav-link", text: "Schools")
    end

    it "hides the school groups menu option" do
      expect(page).to have_no_css(".nav-link", text: "School Groups")
    end

    it "hides the roles menu option" do
      expect(page).to have_no_css(".nav-link", text: "Roles")
    end

    it "shows the add school button" # pending — counterpart for "hides the add school button"
    it "shows the school groups menu option" # pending — counterpart for "hides the school groups menu option"
    it "shows the roles menu option" # pending — counterpart for "hides the roles menu option"
  end

  describe "viewing a school" do
    before { visit(school_path(school)) }

    it "shows the school name" do
      expect(page).to have_content(school.name)
    end

    it "hides the manage role button" do
      expect(page).to have_no_content("Manage User Roles")
    end

    it "shows the manage role button" # pending — counterpart for "hides the manage role button"

    context "when impersonating a student" do
      let!(:student) { create(:student, school: school) }
      before { visit(school_path(school)) }

      it "shows the student as the current user" do
        click_button("Become User")
        expect(page).to have_css("#current_user", text: "#{student.forename} #{student.surname}")
      end
    end

    context "when impersonating a school admin" do
      let!(:school_admin) { create(:school_admin, school: school) }
      before { visit(school_path(school)) }

      it "shows the school admin as the current user" do
        within("#schoolAdminTable") { click_link "Become User" }
        expect(page).to have_css("#current_user", text: "#{school_admin.forename} #{school_admin.surname}")
      end
    end
  end

  describe "viewing subjects" do
    before { visit(subjects_path) }

    it "shows subject statistics" do
      expect(page).to have_content("Questions Asked")
    end

    it "hides the add subject button" do
      expect(page).to have_no_content("Add Subject")
    end

    it "shows the add subject button" # pending — counterpart for "hides the add subject button"
  end
end
