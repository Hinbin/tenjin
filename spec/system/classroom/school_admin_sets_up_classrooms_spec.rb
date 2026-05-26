# frozen_string_literal: true

require "rails_helper"

RSpec.describe "School admin sets up classrooms", :default_creates, :js do
  context "when configuring classrooms" do
    let!(:classroom) { create(:classroom, school: school) }
    let!(:quiz_subject) { create(:subject) }

    before do
      sign_in school_admin
      visit(classrooms_path)
    end

    it "shows which classrooms have been retrieved from Wonde" do
      expect(page).to have_content(classroom.name)
    end

    it "allows setting a subject for the classroom" do
      select quiz_subject.name, from: "subject"
      visit(classrooms_path)
      expect(page).to have_content(quiz_subject.name)
    end

    it "links to the classroom setup page" do
      expect(page).to have_css("a", text: "Setup Classrooms")
    end

    it "shows a sync required message when a subject is set" do
      select quiz_subject.name, from: "subject"
      expect(page).to have_content("School sync required. Click here to start")
    end
  end
end
