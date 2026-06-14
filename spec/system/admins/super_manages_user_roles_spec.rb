# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super manages user roles", :default_creates, :js do
  before { sign_in super_admin }

  shared_examples "a manageable role" do |role_name:, table_id:, requires_subject:|
    let!(:quiz_subject) { create(:subject) } if requires_subject
    let(:full_name) { "#{teacher.forename} #{teacher.surname}" }

    before { visit(manage_roles_system_users_path(school: teacher.school)) }

    it "adds the role to the user" do
      select quiz_subject.name, from: "user[subject]" if requires_subject
      select role_name, from: "user[role]"
      click_button "Add Role"
      within(table_id) { expect(page).to have_content(full_name) }
    end

    context "when the role is already assigned" do
      before do
        requires_subject ? teacher.add_role(role_name.to_sym, quiz_subject) : teacher.add_role(role_name.to_sym)
        visit(manage_roles_system_users_path(school: teacher.school))
      end

      it "removes the role from the user" do
        click_button "Remove"
        expect(page).to have_no_css(table_id)
      end
    end
  end

  describe "school admin role" do
    include_examples "a manageable role",
      role_name: "school_admin", table_id: "#school_admin-table", requires_subject: false
  end

  describe "question author role" do
    include_examples "a manageable role",
      role_name: "question_author", table_id: "#question_author-table", requires_subject: true
  end

  describe "lesson author role" do
    include_examples "a manageable role",
      role_name: "lesson_author", table_id: "#lesson_author-table", requires_subject: true
  end

  describe "employees list" do
    before do
      teacher
      visit(manage_roles_system_users_path(school: school))
    end

    it "lists employees from the school" do
      expect(page).to have_css(".employee-row", count: 1)
    end
  end
end
