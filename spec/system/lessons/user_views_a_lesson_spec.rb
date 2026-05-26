# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User views lessons", :default_creates, :js do
  describe "as a student" do
    let!(:lesson) { create(:lesson, topic: topic) }

    before do
      setup_subject_database
      sign_in student
    end

    context "with enrolled subjects" do
      before { visit(lessons_path) }

      it "shows lesson videos for enrolled subjects" do
        expect(page).to have_css(".subject-title", text: lesson.subject.name)
      end

      it "plays the video when clicked" do
        find(".videoLink").click
        expect(page).to have_css("iframe[src^=\"https://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
      end
    end

    context "with a lesson in an unenrolled subject" do
      let(:second_subject) { create(:subject) }
      let(:second_topic) { create(:topic, subject: second_subject) }
      let!(:not_enrolled_lesson) { create(:lesson, topic: second_topic) }

      before { visit(lessons_path) }

      it "hides lesson videos" do
        expect(page).to have_no_css(".subject-title", text: not_enrolled_lesson.subject.name)
      end
    end

    context "with a lesson that has no video content" do
      let!(:lesson_no_content) { create(:lesson, topic: topic, category: "no_content", video_id: nil) }

      before { visit(lessons_path) }

      it "does not show the lesson" do
        expect(page).to have_no_content(lesson_no_content.title)
      end
    end
  end

  describe "as a teacher" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:question) { create(:question, lesson: lesson, topic: topic) }
    let!(:answer) { create(:answer, question: question) }

    before do
      setup_subject_database
      sign_in teacher
      create(:enrollment, user: teacher, classroom: create(:classroom, school: school, subject: lesson.subject))
      visit(lessons_path)
    end

    it "shows available lesson questions" do
      find("a", text: "View Questions").click
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "shows no questions link when a lesson has no questions" # pending — counterpart missing
  end
end
