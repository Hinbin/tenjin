# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lesson author edits a lesson", :default_creates, :js do
  let!(:lesson) { create(:lesson, topic: topic) }

  before do
    teacher.add_role :lesson_author, quiz_subject
    sign_in teacher
  end

  describe "the lessons index" do
    before { visit(lessons_path) }

    context "with lessons in multiple subjects" do
      let!(:other_lesson) { create(:lesson) }

      it "limits edit list to authored subjects" do
        expect(page)
          .to have_link("Edit", count: 1)
          .and have_css(".subject-title", text: quiz_subject.name)
          .and have_no_css(".subject-title", text: other_lesson.subject.name)
          .and have_content(lesson.title)
          .and have_no_content(other_lesson.title)
      end

      it "limits create list to authored subjects" do
        within("#createLessons") do
          expect(page)
            .to have_css("h1", text: "CREATE LESSONS")
            .and have_css("h3", text: quiz_subject.name)
            .and have_no_css("h3", text: other_lesson.subject.name)
        end
      end
    end
  end

  describe "adding a lesson" do
    before { visit(new_lesson_path(subject: quiz_subject)) }

    it "creates a lesson" do
      fill_in "URL", with: "https://vimeo.com/371104836"
      fill_in "Title", with: "Vimeo video lesson"
      select topic.name, from: "Topic"
      click_button("Create Lesson")
      expect(page).to have_css(".lesson-title", text: "Vimeo video lesson")
    end
  end

  describe "editing a lesson" do
    before { visit(lessons_path) }

    it "saves new lesson details" do
      click_link("Edit")
      fill_in "Title", with: "Fantastic new title"
      click_button("Update Lesson")
      expect(page)
        .to have_css(".videoLink[src=\"#{lesson.reload.video_url}\"]")
        .and have_css(".lesson-title", text: "Fantastic new title")
    end

    it "removes the lesson from the list" do
      page.accept_confirm do
        click_button("Delete")
      end
      expect(page).to have_no_content(lesson.title)
    end
  end
end
