# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User views lessons", :default_creates, :js do
  describe "as a student" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:enrollment) { create(:enrollment, user: student, classroom: classroom) }

    before do
      sign_in student
      visit(lessons_path)
    end

    it "plays the video when clicked" do
      find(".videoLink").click
      expect(page).to have_css("iframe[src^=\"https://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
    end
  end

  describe "as a teacher" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:question) { create(:question, lesson: lesson, topic: topic) }
    let!(:teacher_enrollment) do
      create(:enrollment, user: teacher, classroom: create(:classroom, school: school, subject: lesson.subject))
    end

    before do
      sign_in teacher
      visit(lessons_path)
    end

    it "shows available lesson questions" do
      find("a", text: "View Questions").click
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "shows no questions link when a lesson has no questions" # pending — counterpart missing
  end
end
