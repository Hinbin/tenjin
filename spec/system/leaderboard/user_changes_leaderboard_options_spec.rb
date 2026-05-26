# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User changes leaderboard options", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
    create(:topic_score, topic: topic, user: student)
  end

  context "with no school group" do
    let(:student) { create(:student, school: school_without_school_group) }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "hides the school group option" do
      expect(page).to have_no_button("Select School")
    end
  end

  context "with a school group" do
    before do
      create(:topic_score, school: second_school, topic: topic)
      visit(leaderboard_path(quiz_subject.name))
    end

    it "shows only the current school by default" do
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 1)
    end

    it "filters to show only the user's school" do
      click_button("Select School")
      click_button(student.school.name)
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 1)
    end

    it "shows all schools when toggled" do
      click_button("Select School")
      click_button("All")
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 2)
    end

    it "toggles back to viewing the school group" do
      click_button("Select School")
      click_button("All")
      click_button("All")
      click_button(student.school.name)
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 1)
    end
  end

  context "when viewing all users" do
    before do
      create_list(:topic_score, 50, school: school, topic: topic)
      visit(leaderboard_path(quiz_subject.name))
      expect(page).to have_css("#leaderboardTable tbody tr:nth-child(10)")
    end

    it "shows all entries when toggled" do
      find("#showAll label").click
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 51)
    end

    it "filters back to show only the top entries after deselecting show all" do
      find("#showAll label").click
      expect(page).to have_css("table#leaderboardTable tbody tr:nth-child(51)")
      find("#showAll label").click
      expect(page).to have_css("table#leaderboardTable tbody tr", count: 10)
    end
  end

  context "when viewing the all time leaderboard" do
    let!(:all_time_score) { create(:all_time_topic_score, user: student, topic: topic) }
    let(:second_topic) { create(:topic, subject: quiz_subject) }
    let(:second_subject_topic) { create(:topic) }
    let(:second_student) { create(:student, school: student.school) }
    let(:weekly_score) { topic.topic_scores.find_by!(user: student).score }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "adds up the overall score correctly" do
      find("#allTime label").click
      expect(page).to have_css("td", exact_text: (all_time_score.score + weekly_score).to_s)
    end

    it "defaults to a weekly leaderboard" do
      expect(page).to have_css("td", exact_text: weekly_score)
    end

    context "with scores across multiple topics" do
      let!(:second_all_time_score) { create(:all_time_topic_score, user: student, topic: second_topic) }

      it "adds up a subject score across multiple topics correctly" do
        find("#allTime label").click
        expect(page).to have_css("td", exact_text: (weekly_score + all_time_score.score + second_all_time_score.score).to_s)
      end
    end

    context "with a score in a different subject's topic" do
      let!(:second_subject_all_time_score) { create(:all_time_topic_score, user: student, topic: second_subject_topic) }

      it "adds up scores only for that subject" do
        find("#allTime label").click
        expect(page).to have_css("td", exact_text: (weekly_score + all_time_score.score).to_s)
      end
    end

    context "when viewing a second topic" do
      let!(:second_topic_all_time_score) { create(:all_time_topic_score, user: student, topic: second_topic) }

      before { visit(leaderboard_path(quiz_subject.name, topic: second_topic)) }

      it "adds up scores only for that topic" do
        find("#allTime label").click
        expect(page).to have_css("td", exact_text: second_topic_all_time_score.score)
      end
    end

    context "when the student has no all time score" do
      let!(:second_student_all_time_score) { create(:all_time_topic_score, user: second_student, topic: second_topic) }

      before { all_time_score.destroy }

      it "shows other users' scores" do
        find("#allTime label").click
        expect(page).to have_css("td", exact_text: second_student_all_time_score.score)
      end
    end

    context "when there is no weekly score" do
      before { topic.topic_scores.find_by!(user: student).destroy }

      it "works with only an all time score" do
        find("#allTime label").click
        expect(page).to have_css("td", exact_text: all_time_score.score)
      end
    end
  end

  context "when filtering by classroom" do
    let(:second_classroom) { create(:classroom, subject: quiz_subject, school: school) }
    let(:second_student) { create(:student, school: student.school) }
    let!(:enrollment_classroom) { create(:enrollment, classroom: second_classroom, user: second_student) }
    let!(:topic_score_different_classroom) { create(:topic_score, user: second_student, subject: quiz_subject) }
    let!(:second_school) { create(:school, school_group: school.school_group) }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "shows different classrooms by default" do
      expect(page).to have_css("#leaderboardTable tbody tr", count: 2)
    end

    it "filters by classroom" do
      click_button("Select Class")
      click_button(second_classroom.name)
      expect(page).to have_css("#leaderboardTable tbody tr", count: 1)
    end

    it "changes school back to users when selected" do
      click_button("Select School")
      click_button(second_school.name)
      click_button("Select Class")
      click_button(second_classroom.name)
      expect(page).to have_button("Select School")
    end

    context "with a classroom of the same name in another school" do
      let(:different_school_same_classroom_name) do
        create(:classroom, name: second_classroom.name, school: second_school)
      end
      let!(:different_school_enrollment) { create(:enrollment, classroom: different_school_same_classroom_name) }
      let!(:different_school_topic_score) do
        create(:topic_score, subject: quiz_subject, user: different_school_enrollment.user)
      end

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "filters classrooms with the same name in another school out" do
        click_button("Select Class")
        click_button(second_classroom.name)
        expect(page).to have_css("#leaderboardTable tbody tr", count: 1)
      end
    end
  end
end
