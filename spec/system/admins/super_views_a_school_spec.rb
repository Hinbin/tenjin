# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Super views a school", :default_creates, :js do
  before { sign_in super_admin }

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

  context "when viewing a school" do
    before { visit(school_path(school)) }

    it "links to role management for that school" do
      click_link "Manage User Roles"
      expect(page).to have_current_path(manage_roles_users_path(school: school))
    end
  end

  context "when managing school admin emails" do
    let!(:school_admin) { create(:school_admin, school: school) }
    let(:new_email) { FFaker::Internet.email }
    let(:save_email_notice) { "Updated email to #{school_admin.forename} #{school_admin.surname}" }
    let(:email_notice) do
      "Setup email sent to #{school_admin.forename} #{school_admin.surname} (#{school_admin.email})"
    end

    before { visit(school_path(school)) }

    it "saves email addresses of school admins" do
      fill_in "user-email-#{school_admin.id}", with: new_email
      find("#save-email-#{school_admin.id}").click
      expect(page).to have_css("#flash-notice", text: save_email_notice)
    end

    it "notifies users that a setup email has been sent" do
      click_link "Send Setup Email"
      expect(page).to have_css("#flash-notice", text: email_notice, wait: 6)
    end
  end

  context "when viewing statistics" do
    let(:two_weeks_ago) { (Date.current - 2.weeks).beginning_of_week }
    let!(:statistic) { create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week) }
    let!(:older_statistic) do
      create(:user_statistic, user: create(:student, school: school),
        week_beginning: two_weeks_ago)
    end
    let(:total_answered) { statistic.questions_answered + older_statistic.questions_answered }

    before { visit(school_path(school)) }

    it "shows total questions answered" do
      expect(page).to have_css("#asked_questions", exact_text: total_answered)
    end

    it "shows this week's questions answered" do
      expect(page).to have_css("#asked_questions_weekly", exact_text: statistic.questions_answered)
    end
  end
end
