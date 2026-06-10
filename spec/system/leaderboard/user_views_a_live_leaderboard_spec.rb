# frozen_string_literal: true

require "rails_helper"
require "support/api_data"

RSpec.describe "User views a live leaderboard", :default_creates, :js do
  before { setup_subject_database }

  describe "live toggle visibility" do
    context "as a student" do
      before do
        sign_in student
        visit(leaderboard_path(quiz_subject.name))
      end

      it "does not show the live toggle" do
        expect(page).to have_no_css("#toggleLive")
      end
    end

    context "as a school admin" do
      before do
        sign_in school_admin
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the live toggle" do
        expect(page).to have_css("#toggleLive")
      end
    end
  end

  describe "live leaderboard as a teacher" do
    let!(:student_topic_score) { create(:topic_score, user: student, score: 10, topic: topic) }
    let!(:one_to_nine) do
      (1..9).each { |n| create(:topic_score, topic: topic, school: school, score: n) }
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

      it "shows live updates from a student in the same school group" do
        Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, second_student).call
        expect(page).to have_css("#leaderboardTable tbody tr")
      end

      it "filters live updates by class" do
        click_button("Select Class")
        click_button(enrollment_different_classroom.classroom.name)
        Leaderboard::BroadcastLeaderboardPoint.new(topic_score_different_classroom,
          topic_score_different_classroom.user).call
        expect(page).to have_css(".score-changed").and have_css("tbody tr", count: 1)
      end

      it "filters live updates by school" do
        Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, topic_score_same_school_group.user).call
        click_button("All")
        click_button(topic_score_same_school_group.user.school.name)
        expect(page).to have_css("tbody tr", count: 1)
      end

      context "with an updated score from another school" do
        let!(:topic_score_same_school_group) { create(:topic_score, score: 110, topic: topic, user: second_student) }

        it "shows the live score delta when All is selected" do
          click_button("All")
          Leaderboard::BroadcastLeaderboardPoint.new(topic_score_same_school_group, second_student).call
          expect(page).to have_css("#leaderboardTable tbody tr td#score-#{topic_score_same_school_group.user.id}",
            exact_text: 10)
        end
      end
    end

    context "when the teacher activates the live leaderboard" do
      before do
        sign_in teacher
        visit(leaderboard_path(quiz_subject.name))
        find("#leaderboardTable tbody tr:nth-child(10)")
        find("#toggleLive label").click
      end

      it "resets all scores to zero" do
        expect(page).to have_no_css("tbody tr")
      end

      it "restores weekly scores when toggled off" do
        find("#toggleLive label").click
        expect(page).to have_css("tbody tr", count: 10)
      end

      it "flashes an update when a broadcast arrives" do
        Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score, student_topic_score.user).call
        expect(page).to have_css("tr.score-changed")
      end

      context "with an updated score" do
        let(:add_score) { 500 }

        before do
          student_topic_score.update!(score: student_topic_score.score + add_score)
          student_topic_score.reload
        end

        it "calculates the live score delta correctly" do
          Leaderboard::BroadcastLeaderboardPoint.new(student_topic_score.topic, student_topic_score.user).call
          expect(page).to have_css("td", exact_text: add_score.to_s)
        end
      end
    end
  end
end
