# frozen_string_literal: true

require "rails_helper"

RSpec.describe "lessons controller", :default_creates do
  describe "GET /lessons" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:enrollment) { create(:enrollment, user: student, classroom: classroom) }

    context "as a student" do
      let!(:no_content_lesson) do
        create(:lesson, topic: topic, category: "no_content", video_id: nil)
      end

      before { sign_in student }

      it "hides no_content lessons" do
        get lessons_path

        expect(response.body).to include(lesson.title)
        expect(response.body).not_to include(no_content_lesson.title)
      end
    end

    context "as a lesson author" do
      before do
        teacher.add_role :lesson_author, quiz_subject
        sign_in teacher
      end

      it "shows a create lesson link for authored subjects" do
        get lessons_path

        expect(response.body)
          .to include("Create #{quiz_subject.name} Lesson")
          .and include(new_lesson_path(subject: quiz_subject))
      end
    end
  end
end
