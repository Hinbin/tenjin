# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User views lessons', type: :system, js: true, default_creates: true do
  let(:lesson) { create(:lesson, topic: topic) }

  context 'when a student' do
    let(:second_subject) { create(:subject) }
    let(:second_topic) { create(:topic, subject: second_subject) }
    let(:not_enrolled_lesson) { create(:lesson, topic: second_topic) }
    let(:lesson_no_content) { create(:lesson, topic: topic, category: 'no_content', video_id: nil) }

    before do
      setup_subject_database
      sign_in student
      lesson
    end

    it 'shows videos for subjects I am enrolled for' do
      visit(lessons_path)
      expect(page).to have_css('.subject-title', text: lesson.subject.name)
    end

    it 'only shows videos for subjects I am enrolled for' do
      not_enrolled_lesson
      visit(lessons_path)
      expect(page).to have_no_css('.subject-title', text: not_enrolled_lesson.subject.name)
    end

    it 'ignores lessons with no video link ' do
      lesson_no_content
      visit(lessons_path)
      expect(page).to have_no_content(lesson_no_content.title)
    end

    it 'plays the video when clicked on' do
      visit(lessons_path)
      find(:css, '.videoLink').click
      expect(page).to have_css("iframe[src^=\"https://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
    end
  end

  context 'when a teacher' do
    let(:question) { create(:question, lesson: lesson, topic: topic) }
    let(:answer) { create(:answer, question: question) }

    before do
      setup_subject_database
      sign_in teacher
      answer
      lesson
      create(:enrollment, user: teacher, classroom: create(:classroom, school: school, subject: lesson.subject))
      visit(lessons_path)
    end

    it 'shows what questions are available for each lesson' do
      find('a', text: 'View Questions').click
      expect(page).to have_content(question.question_text.to_plain_text)
    end
  end
end
