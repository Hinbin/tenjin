# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teacher sets homework", :default_creates, :js do
  let!(:topic) { create(:topic, subject: quiz_subject) }

  before do
    sign_in teacher
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
  end

  describe "submitting the homework form" do
    before do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework
      click_button("Set Homework")
    end

    it "shows a success message on the classroom's homework page" do
      expect(page).to have_css(".alert-info", text: "homework set")
        .and have_content(classroom.name)
    end
  end

  describe "selecting a lesson on the homework form" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let(:question_count) { 10 }
    let!(:questions) { create_list(:question, question_count, lesson: lesson, topic: topic) }

    before { visit(new_homework_path(classroom: {classroom_id: classroom.id})) }

    context "with no topic selected" do
      it "does not list any lessons" do
        expect(page).to have_no_content(lesson.title)
      end
    end

    context "with a topic selected" do
      before { select topic.name, from: "Topic" }

      it "lists lessons for that topic" do
        expect(page).to have_content(lesson.title)
      end

      context "when the lesson has fewer than 10 questions" do
        let(:question_count) { 9 }

        it "does not list the lesson" do
          expect(page).to have_no_content(lesson.title)
        end
      end

      context "with a lesson belonging to a different topic" do
        let!(:other_lesson) do
          other_topic = create(:topic, subject: quiz_subject)
          other = create(:lesson, topic: other_topic)
          create_list(:question, 10, lesson: other, topic: other_topic)
          other
        end

        it "does not list the other topic's lesson" do
          expect(page).to have_no_content(other_lesson.title)
        end
      end
    end
  end

  describe "submitting a lesson homework" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:questions) { create_list(:question, 10, lesson: lesson, topic: topic) }

    before do
      visit(new_homework_path(classroom: {classroom_id: classroom.id}))
      create_homework_for_lesson
      click_button("Set Homework")
    end

    it "shows a success message" do
      expect(page).to have_css(".alert-info", text: "homework set")
    end
  end
end
