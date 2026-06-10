# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User views the leaderboard", :default_creates, :js do
  # "Aaaron" sorts before random factory forenames, making ranking deterministic
  let(:student) { create(:student, forename: "Aaaron", school: school) }
  let!(:topic_score) { create(:topic_score, topic: topic, user: student) }
  let(:student_name) { initialize_name(student) }

  before do
    setup_subject_database
    sign_in student
  end

  context "with the student's score on the leaderboard" do
    before { visit(leaderboard_path(quiz_subject.name)) }

    it "displays the current student" do
      expect(page).to have_css("td", exact_text: student_name)
    end
  end

  context "when another student has a score" do
    let(:second_student) { create(:student, school: school) }
    let!(:second_topic_score) { create(:topic_score, topic: topic, user: second_student) }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "displays the other student" do
      expect(page).to have_css("td", exact_text: initialize_name(second_student))
    end
  end

  context "when a student from another school has a score" do
    let(:other_student) { create(:student) }
    let!(:other_topic_score) { create(:topic_score, topic: topic, user: other_student) }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "does not show the student from another school" do
      expect(page).to have_no_css("td", exact_text: initialize_name(other_student))
    end
  end

  context "with 10 other students on the leaderboard" do
    before do
      10.times { |n| create(:topic_score, topic: topic, school: school, score: n + 1) }
    end

    context "when the student's score is mid-table" do
      let(:student) { create(:student, forename: "Aaron", school: school) }
      let!(:topic_score) { create(:topic_score, topic: topic, user: student, score: 5) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "ranks the student at row 6 with the highest score at row 1" do
        expect(page).to have_css("tr:nth-child(1)", text: "10")
          .and have_css("tr:nth-child(6)", text: student_name)
      end

      it "shows the student's rank within the school" do
        expect(page).to have_css("tr", text: "6 #{student_name}", normalize_ws: true)
      end
    end

    context "when the student is at the top of the leaderboard" do
      let!(:topic_score) { create(:topic_score, topic: topic, user: student, score: 50) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows the student alongside the top 10" do
        expect(page).to have_css("table#leaderboardTable tr", count: 11)
      end
    end

    context "when the student has no score" do
      let!(:topic_score) { nil }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows the top 10 ranks" do
        expect(page).to have_css("table#leaderboardTable tbody tr", count: 10)
          .and have_css("tr:nth-child(10) td", exact_text: "10")
      end
    end

    context "when the student is at the bottom of the leaderboard" do
      let!(:topic_score) { create(:topic_score, topic: topic, user: student, score: 0) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows the student's score of 0 at row 10" do
        expect(page).to have_css("tr:nth-child(10) td:nth-child(6)", text: "0")
      end
    end

    context "when the student is near the bottom" do
      let!(:topic_score) { create(:topic_score, topic: topic, user: student, score: 3) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "places the student at row 8" do
        expect(page).to have_css("tr:nth-child(8) td:nth-child(3)", text: student.forename)
      end
    end
  end

  context "when viewing leaderboard icons" do
    let(:blue_star) do
      create(:customisation, customisation_type: "leaderboard_icon", value: "blue,star", name: "Blue Star")
    end
    let(:pink_star) do
      create(:customisation, customisation_type: "leaderboard_icon", value: "pink,star", name: "Pink Star")
    end

    before do
      10.times { |n| create(:topic_score, topic: topic, school: school, score: n + 1) }
    end

    context "with a blue star customisation" do
      before do
        create(:active_customisation, user: student, customisation: blue_star)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the student's blue star icon" do
        expect(page).to have_css("td i.fa-star", style: "color: blue;")
      end
    end

    context "with a pink star customisation" do
      before do
        create(:active_customisation, user: student, customisation: pink_star)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the student's pink star icon" do
        expect(page).to have_css("td i.fa-star", style: "color: pink;")
      end
    end
  end

  describe "subject overall score" do
    context "with scores across multiple topics in the same subject" do
      let!(:second_topic_score) { create(:topic_score, user: student, topic: create(:topic, subject: quiz_subject)) }
      let(:overall_total) { topic_score.score + second_topic_score.score }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "adds up scores from different topics" do
        expect(page).to have_css("tr.current-user td:nth-child(4)", exact_text: overall_total)
      end
    end

    context "with a score in a topic from a different subject" do
      let!(:second_subject_score) { create(:topic_score, user: student, topic: create(:topic)) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "ignores scores from topics of a different subject" do
        expect(page).to have_css("tr.current-user td:nth-child(4)", exact_text: topic_score.score)
      end
    end
  end

  describe "weekly awards" do
    let!(:award) do
      create(:leaderboard_award, user: topic_score.user, subject: topic_score.subject, school: topic_score.user.school)
    end

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "shows a red star for a weekly award" do
      expect(page).to have_css("td i.fa-star", style: "color: red;")
    end

    context "with 6 or more wins" do
      let!(:extra_awards) do
        create_list(:leaderboard_award, 5, user: topic_score.user,
          subject: topic_score.subject, school: topic_score.user.school)
      end

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows a gold star" do
        expect(page).to have_css("td i.fa-star", style: "color: gold;")
      end
    end

    context "with 3 or more wins" do
      let!(:extra_awards) do
        create_list(:leaderboard_award, 2, user: topic_score.user, subject: topic_score.subject,
          school: topic_score.user.school)
      end

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows a silver star" do
        expect(page).to have_css("td i.fa-star", style: "color: silver;")
      end
    end

    context "when multiple users have awards" do
      let!(:other_topic_score) { create(:topic_score, topic: topic, school: school) }
      let!(:other_award) do
        create(:leaderboard_award,
          user: other_topic_score.user,
          subject: other_topic_score.subject,
          school: other_topic_score.user.school)
      end

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows a red star for each" do
        expect(page).to have_css("td i.fa-star", style: "color: red;", count: 2)
      end
    end
  end

  describe "weekly winners" do
    let!(:classroom_winner) { create(:classroom_winner, user: student, classroom: classroom, score: 100) }

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "shows last week's winner for the classroom" do
      click_button("Select Class")
      click_button(classroom.name)
      expect(page).to have_content("#{classroom.name} winner: #{student.forename}")
    end
  end
end
