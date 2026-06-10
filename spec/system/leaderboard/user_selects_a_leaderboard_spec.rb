# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User selects a leaderboard", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  context "with a topic and a second subject enrolled" do
    let!(:topic) { super() }
    let(:second_subject) { create(:subject) }
    let(:second_classroom) { create(:classroom, subject: second_subject, school: school) }

    before do
      create(:enrollment, classroom: second_classroom, user: student)
      visit leaderboard_index_path
    end

    it "allows selecting a topic leaderboard" do
      click_link(quiz_subject.name)
      within(".collapse.show") { click_link(topic.name) }
      expect(page).to have_css("h1", text: topic.name)
    end

    it "allows selecting the overall subject leaderboard" do
      click_link(quiz_subject.name)
      within(".collapse.show") { click_link("All") }
      expect(page).to have_css("h1", text: quiz_subject.name)
    end

    it "shows leaderboards for multiple subjects" do
      click_link(second_subject.name)
      within(".collapse.show") { click_link("All") }
      expect(page).to have_css("h1", text: second_subject.name)
    end
  end

  context "when the leaderboard has been loaded" do
    before do
      create(:topic_score, user: student, topic: topic)
      visit leaderboard_index_path
    end

    it "highlights the current user" do
      click_link(quiz_subject.name)
      within(".collapse.show") { click_link("All") }
      expect(page).to have_css("tr.current-user")
    end
  end
end
