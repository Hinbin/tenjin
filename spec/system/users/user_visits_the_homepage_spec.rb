# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe "User visits the homepage", :default_creates, :js, :vcr do
  include_context "with api_data"
  include_context "with wonde_test_data"

  context "when looking at the page" do
    subject { page }

    before { visit root_path }

    it { is_expected.to have_button("Login") }
    it { is_expected.to have_content("TENJIN") }
    it { is_expected.to have_link("About") }
    it { is_expected.to have_css("nav.fixed-top") }
  end

  context "when logging in" do
    let!(:student) { create(:student) }

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
      let!(:google_student) { create(:student, oauth_uid: "123456123456") }

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

  context "when looking at the about page" do
    before do
      hide_const("OGAT")
      visit page_path("about")
    end

    it "shows the about page" do
      expect(page).to have_css("#standardAbout")
    end

    it "does not have a fixed top nav bar" do
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

  context "when being prompted to sign in with Google" do
    context "with an unlinked account" do
      before do
        sign_in create(:student, :no_oauth)
        visit(dashboard_path)
      end

      it "prompts to link their account" do
        expect(page).to have_content("Let's get your account linked")
      end
    end

    context "with a linked account" do
      before do
        sign_in student
        visit(dashboard_path)
      end

      it "does not prompt to link their account" do
        expect(page).to have_no_content("Let's get your account linked")
      end
    end

    context "with an unlinked teacher account" do
      before do
        sign_in create(:teacher, :no_oauth)
        visit(dashboard_path)
      end

      it "prompts to link their account" do
        expect(page).to have_content("Let's get your account linked")
      end
    end

    it "only displays the message when the MAT is Google enabled"
  end
end
