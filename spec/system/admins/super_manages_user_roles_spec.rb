# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super manages user roles", :default_creates, :js do
  let!(:quiz_subject) { create(:subject) }

  before { sign_in super_admin }

  describe "school admin role" do
    before { visit(manage_roles_users_path(school: teacher.school)) }

    it "adds the role" do
      select "school_admin", from: "user[role]"
      click_button("Add Role")
      within("#school_admin-table") { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
    end

    context "when the role is assigned" do
      before do
        teacher.add_role :school_admin
        visit(manage_roles_users_path(school: teacher.school))
      end

      it "removes the role" do
        click_button("Remove")
        expect(page).to have_no_css("#school_admin-table")
      end
    end
  end

  describe "question author role" do
    before { visit(manage_roles_users_path(school: teacher.school)) }

    it "adds the role" do
      select quiz_subject.name, from: "user[subject]"
      select "question_author", from: "user[role]"
      click_button("Add Role")
      within("#question_author-table") { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
    end

    context "when the role is assigned" do
      before do
        teacher.add_role :question_author, quiz_subject
        visit(manage_roles_users_path(school: teacher.school))
      end

      it "removes the role" do
        click_button("Remove")
        expect(page).to have_no_css("#question_author-table")
      end
    end
  end

  describe "lesson author role" do
    before { visit(manage_roles_users_path(school: teacher.school)) }

    it "adds the role" do
      select quiz_subject.name, from: "user[subject]"
      select "lesson_author", from: "user[role]"
      click_button("Add Role")
      within("#lesson_author-table") { expect(page).to have_content("#{teacher.forename} #{teacher.surname}") }
    end

    context "when the role is assigned" do
      before do
        teacher.add_role :lesson_author, quiz_subject
        visit(manage_roles_users_path(school: teacher.school))
      end

      it "removes the role" do
        click_button("Remove")
        expect(page).to have_no_css("#lesson_author-table")
      end
    end
  end

  describe "employees" do
    let!(:teacher) { create(:teacher, school: school) }

    before do
      visit(school_path(school))
      click_link "Manage User Roles"
    end

    it "shows employees" do
      expect(page).to have_css(".employee-row", count: 1)
    end
  end
end
