# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lesson author edits a lesson", :default_creates, :js do
  let!(:lesson) { create(:lesson, topic: topic) }

  before do
    teacher.add_role :lesson_author, quiz_subject
    sign_in teacher
  end

  describe "visiting the lessons index" do
    before do
      visit(lessons_path)
    end

    it "navigates to the new lesson form" do
      click_link("Create #{quiz_subject.name} Lesson")
      expect(page).to have_current_path(new_lesson_path, ignore_query: true)
    end

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

    it "creates a lesson without a video link" do
      fill_in "Title", with: "No video lesson"
      select topic.name, from: "Topic"
      click_button("Create Lesson")
      expect(page).to have_css("td", text: "No video lesson")
    end

    it "creates a lesson with a supported video link" do
      fill_in "URL", with: "https://vimeo.com/371104836"
      fill_in "Title", with: "Vimeo video lesson"
      select topic.name, from: "Topic"
      click_button("Create Lesson")
      expect(page).to have_css(".lesson-title", text: "Vimeo video lesson")
    end

    it "shows an error with an unsupported video link" do
      fill_in "URL", with: "https://badtube.com/t-ZRX8984sc"
      fill_in "Title", with: "Bad video lesson"
      select topic.name, from: "Topic"
      click_button("Create Lesson")
      expect(page).to have_content("Must be a YouTube or Vimeo link")
    end
  end

  describe "editing a lesson" do
    before do
      setup_subject_database
      create(:enrollment, user: teacher, subject: quiz_subject)
      visit(lessons_path)
    end

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
        click_link("Delete")
      end
      expect(page).to have_no_css(".videoLink")
    end
  end
end
