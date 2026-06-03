# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for lesson viewing flows.
# Non-interactive tests have been converted to spec/requests/lessons_request_spec.rb.
RSpec.describe 'User views lessons', :default_creates, :js, :vcr, type: :system do
  let(:lesson) { create(:lesson, topic:) }

  context 'when a student' do
    before do
      setup_subject_database
      sign_in student
      lesson
    end

    it 'plays the video when clicked on' do
      visit(lessons_path)
      find(:css, '.videoLink').click
      expect(page).to have_css("iframe[src^=\"https://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
    end
  end

  context 'when a teacher' do
    let(:question) { create(:question, lesson:, topic:) }
    let(:answer) { create(:answer, question:) }

    before do
      setup_subject_database
      sign_in teacher
      answer
      lesson
      create(:enrollment, user: teacher, classroom: create(:classroom, school:, subject: lesson.subject))
      visit(lessons_path)
    end

    it 'shows what questions are available for each lesson' do
      find('a', text: 'View Questions').click
      expect(page).to have_text(question.question_text.to_plain_text)
    end
  end
end
