# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student visits the student record", :default_creates, :js, :vcr do
  let(:student) { create(:student) }
  let(:new_password) { FFaker::Lorem.word }

  before do
    sign_in student
    stub_google_omniauth
    visit(user_path(student))
  end

  def log_in_via_google
    sign_out student
    visit root_path
    click_button "Login"
    find_by_id("loginGoogle").click
    find(".alert", text: "authenticated")
  end

  it "changes the password" do
    update_password(new_password)
    log_in_through_front_page(student.username, new_password)
    expect(page).to have_content(student.forename).and have_content(student.surname)
  end

  it "unlinks a Google account" do
    page.accept_confirm { click_button "Unlink #{student.oauth_email}" }
    expect(page).to have_css("#loginGoogle")
  end

  context "when linking Google accounts" do
    let(:student_no_oauth) { create(:student, :no_oauth) }

    before do
      sign_in student_no_oauth
      visit(user_path(student_no_oauth))
    end

    it "links a Google account" do
      find_by_id("loginGoogle").click
      find(".alert", text: "linked")
      log_in_via_google
      expect(page).to have_content(student_no_oauth.forename).and have_content(student_no_oauth.surname)
    end

    it "shows a success message" do
      find(".shepherd-text")
      find_by_id("loginGoogle").click
      expect(page).to have_content("Successfully linked Google account")
    end
  end
end
