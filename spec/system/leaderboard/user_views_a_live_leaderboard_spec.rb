# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe "User views a live leaderboard", :default_creates, :js do
  let!(:student_topic_score) { create(:topic_score, user: student, score: 10, topic: topic) }
  let!(:one_to_nine) do
    (1..9).each { |n| create(:topic_score, topic: topic, school: school, score: n) }
  end

  before { setup_subject_database }

  describe "as a student" do
    before do
      sign_in student
      visit(leaderboard_path(quiz_subject.name))
    end

    it "does not show the live toggle" do
      expect(page).to have_no_css("#toggleLive")
    end
  end

  describe "as a school admin" do
    before do
      sign_in school_admin
      visit(leaderboard_path(quiz_subject.name))
    end

    it "shows the live toggle" do
      expect(page).to have_css("#toggleLive")
    end
  end

  context "with a school group" do
    let(:second_student) { create(:student, school: second_school) }
    let!(:second_school) { create(:school, school_group: school.school_group) }
    let!(:topic_score_same_school_group) { create(:topic_score, score: 100, topic: topic, user: second_student) }
    let(:student_same_school) { create(:student, school: school) }
    let!(:enrollment_different_classroom) do
      create(:enrollment,
        user: student_same_school,
        classroom: create(:classroom, subject: quiz_subject, school: school))
    end
    let(:topic_score_different_classroom) { create(:topic_score, score: 100, topic: topic, user: student_same_school) }

    before do
      sign_in teacher
      visit(leaderboard_path(quiz_subject.name))
      find("#leaderboardTable tbody tr:nth-child(10)")
      find("#toggleLive label", visible: false).click
    end

    it "resets all scores to 0 when live leaderboard selected" do
      expect(page).to have_css("tbody tr", count: 0)
    end

    it "shows updates from all schools only by default" do
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, second_student).call
      expect(page).to have_css("#leaderboardTable tbody tr")
    end

    context "with an updated score from another school" do
      let!(:topic_score_same_school_group) { create(:topic_score, score: 110, topic: topic, user: second_student) }

      it "shows updates from other schools when selected" do
        click_button("All")
        Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, second_student).call
        expect(page).to have_css("#leaderboardTable tbody tr td#score-#{topic_score_same_school_group.user.id}",
          exact_text: 10)
      end
    end

    it "filters updates by class" do
      click_button("Select Class")
      click_button(enrollment_different_classroom.classroom.name)
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_different_classroom,
        topic_score_different_classroom.user).call
      expect(page).to have_css(".score-changed").and have_css("tbody tr", count: 1)
    end

    it "filters updates by school" do
      Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, topic_score_same_school_group.user).call
      click_button("All")
      click_button(topic_score_same_school_group.user.school.name)
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  context "when an employee" do
    let(:add_score) { 500 }

    before do
      sign_in teacher
      visit(leaderboard_path(quiz_subject.name))
      find("#leaderboardTable tbody tr:nth-child(10)")
      find("#toggleLive label").click
    end

    it "shows the live toggle" do
      expect(page).to have_css("#toggleLive")
    end

    it "resets all scores to zero" do
      expect(page).to have_no_css("tbody tr")
    end

    it "shows weekly scores when turned off" do
      find("#toggleLive label").click
      expect(page).to have_css("tbody tr", count: 10)
    end

    it "shows an update after being turned on" do
      Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score, student_topic_score.user).call
      expect(page).to have_css("tr.score-changed")
    end

    context "with an updated score" do
      before do
        student_topic_score.update!(score: student_topic_score.score + add_score)
        student_topic_score.reload
      end

      it "calculates the score correctly" do
        Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score.topic, student_topic_score.user).call
        expect(page).to have_css("td", exact_text: add_score.to_s)
      end
    end
  end
end
