# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User views the leaderboard", :default_creates, :js do
  let(:student) { create(:student, forename: "Aaaron", school: school) } # Ensure first alphabetically
  let!(:topic_score) { create(:topic_score, topic: topic, user: student) }
  let(:student_name) { initialize_name student }
  let(:second_student) { create(:student, school: school) }
  let(:another_name) { initialize_name second_student }

  before do
    setup_subject_database
    sign_in student
  end

  it "displays the current student when they have a score" do
    visit(leaderboard_path(quiz_subject.name))
    expect(page).to have_css("td", exact_text: student_name)
  end

  context "when another student has a score" do
    before do
      create(:topic_score, topic: topic, user: second_student)
      visit(leaderboard_path(quiz_subject.name))
    end

    it "displays the other student" do
      expect(page).to have_css("td", exact_text: another_name)
    end
  end

  context "when a student from another school has a score" do
    let(:other_student) { create(:student) }

    before do
      create(:topic_score, topic: topic, user: other_student)
      visit(leaderboard_path(quiz_subject.name))
    end

    it "does not show the student from another school" do
      expect(page).to have_no_css("td", exact_text: initialize_name(other_student))
    end
  end

  it "hides schools on a small screen" do
    size = page.driver.browser.manage.window.size
    visit(leaderboard_path(quiz_subject.name))
    page.driver.browser.manage.window.resize_to(375, 667)
    expect(page).to have_no_css("td", exact_text: school.name)
    page.driver.browser.manage.window.resize_to(size.width, size.height)
  end

  context "when there are 10 other students" do
    let!(:one_to_ten) do
      (1..10).each do |n|
        create(:topic_score, topic: topic, school: school, score: n)
      end
    end

    context "when the student is in the middle of the table" do
      before do
        topic_score.update!(score: 5)
        student.update!(forename: "Aaron") # Ensure first alphabetically
        visit(leaderboard_path(quiz_subject.name))
      end

      it "puts the scores in order" do
        expect(page).to have_css("tr:nth-child(6)", text: student_name)
      end

      it "shows the student's position within the school" do
        expect(page).to have_css("tr", text: "6 #{student_name}")
      end
    end

    context "when the student is near the top" do
      before do
        topic_score.update!(score: 5)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "defaults to show 10 entries" do
        expect(page).to have_css("table#leaderboardTable tr", count: 11)
      end
    end

    context "when the student has no score" do
      before do
        topic_score.destroy
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the top 10" do
        expect(page).to have_css("tr:nth-child(10) td", exact_text: "10")
      end
    end

    context "when the student is at the top of the table" do
      before do
        topic_score.update!(score: 50)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the student" do
        expect(page).to have_css("table#leaderboardTable tr", count: 11)
      end
    end

    context "when the student is at the bottom of the table" do
      before do
        topic_score.update!(score: 0)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows the student at the bottom" do
        expect(page).to have_css("tr:nth-child(10) td:nth-child(6)", text: topic_score.reload.score)
      end
    end

    context "when the student is near the bottom" do # bug
      before do
        topic_score.update!(score: 3)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows other students" do
        expect(page).to have_css("tr:nth-child(8) td:nth-child(3)", text: student.forename)
      end
    end
  end

  context "when viewing leaderboard icons" do
    let(:blue_star) do
      create(:customisation, customisation_type: "leaderboard_icon",
        value: "blue,star", name: "Blue Star")
    end

    let(:pink_star) do
      create(:customisation, customisation_type: "leaderboard_icon",
        value: "pink,star", name: "Pink Star")
    end

    let!(:one_to_ten) do
      (1..10).each do |n|
        create(:topic_score, topic: topic, school: school, score: n)
      end
    end

    before do
      create(:active_customisation, user: student, customisation: blue_star)
      visit(leaderboard_path(quiz_subject.name))
    end

    it "shows the leaderboard icon for a person" do
      expect(page).to have_css("td svg.fa-star", style: "color: blue;")
    end

    it "shows a blank space if there is no leaderboard icon" do
      expect(page).to have_no_css("td svg.fa-star", count: 11)
    end

    context "with a pink star customisation" do
      before do
        ActiveCustomisation.destroy_all
        create(:active_customisation, user: student, customisation: pink_star)
        visit(leaderboard_path(quiz_subject.name))
      end

      it "shows different colours of leaderboard icons" do
        expect(page).to have_css("td svg.fa-star", style: "color: pink;")
      end
    end
  end

  context "when viewing a subjects overall score" do
    context "when the student has scores across multiple topics in the same subject" do
      let!(:second_topic_score) { create(:topic_score, user: student, topic: create(:topic, subject: quiz_subject)) }
      let(:overall_total) { topic_score.score + second_topic_score.score }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "adds up scores from different topics" do
        expect(page).to have_css("tr.current-user td:nth-child(4)", exact_text: overall_total)
      end
    end

    context "when the student has a score in a topic from a different subject" do
      let!(:second_subject_score) { create(:topic_score, user: student, topic: create(:topic)) }

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "ignores scores from topics of a different subject" do
        expect(page).to have_css("tr.current-user td:nth-child(4)", exact_text: topic_score.score)
      end
    end
  end

  context "when viewing weekly awards" do
    let!(:award) do
      create(:leaderboard_award, user: topic_score.user, subject: topic_score.subject, school: topic_score.user.school)
    end

    before { visit(leaderboard_path(quiz_subject.name)) }

    it "shows a star for a weekly award" do
      expect(page).to have_css("td svg.fa-star", style: "color: red;")
    end

    context "with 6 or more wins" do
      let!(:extra_awards) do
        create_list(:leaderboard_award, 5, user: topic_score.user,
          subject: topic_score.subject, school: topic_score.user.school)
      end

      it "shows a gold star" do
        expect(page).to have_css("td svg.fa-star", style: "color: gold;")
      end
    end

    context "with 3 or more wins" do
      let!(:extra_awards) do
        create_list(:leaderboard_award, 2, user: topic_score.user, subject: topic_score.subject,
          school: topic_score.user.school)
      end

      it "shows a silver star" do
        expect(page).to have_css("td svg.fa-star", style: "color: silver;")
      end
    end

    context "when multiple users have awards" do
      let!(:one_to_nine) do
        (1..9).each { |n| create(:topic_score, topic: topic, school: school, score: n) }
      end
      let!(:second_award_score) { topic.topic_scores.where.not(user: student).first }
      let!(:second_award) do
        create(:leaderboard_award,
          user: second_award_score.user,
          subject: second_award_score.subject,
          school: second_award_score.user.school)
      end

      before { visit(leaderboard_path(quiz_subject.name)) }

      it "shows a star for each" do
        expect(page).to have_css("td svg.fa-star", style: "color: red;", count: 2)
      end
    end
  end

  context "when showing weekly winners" do
    before { visit(leaderboard_path(quiz_subject.name)) }

    it "shows last week's winner for the classroom" do
      create(:classroom_winner, user: student, classroom: classroom, score: 100)
      click_button("Select Class")
      click_button(classroom.name)
      expect(page).to have_content("#{classroom.name} winner: #{student.forename}")
    end
  end
end
