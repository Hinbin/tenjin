# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User visits the homepage", :default_creates, :js, :vcr do
  describe "the landing page" do
    before { visit root_path }

    it "shows the brand, login button, about link, and fixed nav" do
      expect(page).to have_button("Login")
        .and have_content("TENJIN")
        .and have_link("About")
        .and have_css("nav.fixed-top")
    end
  end

  describe "logging in" do
    before { visit root_path }

    it "pops up the login form" do
      click_button "Login"
      expect(page).to have_content("Login").and have_content("Password")
    end

    it "logs in a student by username" do
      log_in_through_front_page(student.username, student.password)
      expect(page).to have_content(student.forename).and have_content(student.surname)
    end

    it "logs in a teacher by email" do
      log_in_through_front_page(teacher.username, teacher.password)
      expect(page).to have_content(teacher.forename).and have_content(teacher.surname)
    end

    context "with a Google-linked account" do
      let!(:google_student) { create(:student, school: school, oauth_uid: "123456123456") }

      before { stub_google_omniauth }

      it "logs in via Google OAuth" do
        click_button "Login"
        find_by_id("loginGoogle").click
        expect(page).to have_content(google_student.forename).and have_content(google_student.surname)
      end
    end

    context "when already signed in" do
      before { sign_in student }

      it "redirects to the dashboard" do
        visit("/")
        expect(page).to have_content(student.forename).and have_content(student.surname)
      end
    end

    context "when Google login fails" do
      before { stub_google_omniauth }

      it "displays a login error message" do
        click_button "Login"
        find_by_id("loginGoogle").click
        expect(page).to have_text("Your account has not been found")
      end
    end
  end

  describe "the about page" do
    context "with the OGAT constant hidden" do
      before do
        hide_const("OGAT")
        visit page_path("about")
      end

      it "shows the standard about page" do
        expect(page).to have_css("#standardAbout")
      end

      it "hides the fixed top nav bar" do
        expect(page).to have_no_css("nav.fixed-top")
      end
    end

    context "with the OGAT environment variable set" do
      before do
        stub_const("ENV", "OGAT" => "true")
        visit page_path("about")
      end

      it "shows the OGAT about page" do
        expect(page).to have_css("#ogatAbout")
      end
    end
  end

  describe "the Google account link prompt" do
    context "with an unlinked student account" do
      let!(:unlinked_student) { create(:student, :no_oauth, school: school) }

      before do
        sign_in unlinked_student
        visit(dashboard_path)
      end

      it "prompts to link the account" do
        expect(page).to have_content("Let's get your account linked")
      end
    end

    context "with a linked student account" do
      before do
        sign_in student
        visit(dashboard_path)
      end

      it "does not prompt to link the account" do
        expect(page).to have_no_content("Let's get your account linked")
      end
    end

    context "with an unlinked teacher account" do
      let!(:unlinked_teacher) { create(:teacher, :no_oauth, school: school) }

      before do
        sign_in unlinked_teacher
        visit(dashboard_path)
      end

      it "prompts to link the account" do
        expect(page).to have_content("Let's get your account linked")
      end
    end
  end
end
