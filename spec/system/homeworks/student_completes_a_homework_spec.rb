# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Student completes a homework", :default_creates, :js do
  before do
    setup_subject_database
    sign_in student
  end

  context "when completing a homework" do
    let!(:homework_ten_percent) { create(:homework, topic: topic, classroom: classroom, required: 10) }
    let!(:answer) { create(:answer, question: question, correct: true) }

    before { visit(dashboard_path) }

    it "completes a homework" do
      find(".homework-row[data-homework='#{homework_ten_percent.id}']").click
      find(".question-button", match: :first).click
      find(".next-button", match: :first).click
      expect(page).to have_css(".homework-row > td > svg.fa-check")
    end
  end

  context "when completing a lesson homework" do
    let(:lesson) { create(:lesson, topic: topic) }
    let!(:homework_with_lesson) do
      create(:homework, lesson: lesson, topic: lesson.topic, classroom: classroom, required: 10)
    end

    before do
      create_list(:question, 10, topic: lesson.topic, lesson: lesson)
      visit(dashboard_path)
    end

    it "only gives questions assigned to that lesson" do
      find(".homework-row[data-homework='#{homework_with_lesson.id}']").click
      expect(page).to have_css("#quiz-name", exact_text: lesson.title)
    end

    context "when the student has already started the lesson today" do
      let!(:usage_statistic) do
        create(:usage_statistic, lesson: lesson, topic: lesson.topic, user: student,
          quizzes_started: 1, date: Date.current)
      end
      before { visit(dashboard_path) }

      it "awards no leaderboard points" do
        find(".homework-row[data-homework='#{homework_with_lesson.id}']").click
        find(".trix-content")
        expect(page).to have_content("This quiz is currently not counting towards your leaderboard points")
      end
    end
  end
end
