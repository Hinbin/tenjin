# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student completes a homework", :default_creates, :js do
  let(:question) { create(:question, topic: topic) }

  before do
    setup_subject_database
    sign_in student
  end

  context "with a topic homework" do
    let!(:homework) { create(:homework, topic: topic, classroom: classroom, required: 10) }
    let!(:answer) { create(:answer, question: question, correct: true) }

    before { visit(dashboard_path) }

    it "shows a tick next to the homework row on completion" do
      find(".homework-row[data-homework='#{homework.id}']").click
      find(".question-button", match: :first).click
      find(".next-button", match: :first).click
      expect(page).to have_css(".homework-row > td > i.fa-check")
    end

    context "with the homework not yet started" do
      it "does not show a tick next to the homework row"
    end
  end

  context "with a lesson homework" do
    let(:lesson) { create(:lesson, topic: topic) }
    let!(:homework) { create(:homework, lesson: lesson, topic: topic, classroom: classroom, required: 10) }

    before do
      create_list(:question, 10, topic: topic, lesson: lesson)
      visit(dashboard_path)
    end

    it "names the quiz after the lesson" do
      find(".homework-row[data-homework='#{homework.id}']").click
      expect(page).to have_css("#quiz-name", exact_text: lesson.title)
    end

    context "when the student has already started the lesson today" do
      let!(:usage_statistic) do
        create(:usage_statistic, lesson: lesson, topic: topic, user: student,
          quizzes_started: 1, date: Date.current)
      end
      before { visit(dashboard_path) }

      it "warns that the quiz will not count toward leaderboard points" do
        find(".homework-row[data-homework='#{homework.id}']").click
        expect(page).to have_content("This quiz is currently not counting towards your leaderboard points")
      end
    end
  end
end
