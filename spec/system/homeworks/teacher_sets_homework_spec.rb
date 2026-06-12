# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for homework creation flows.
# Non-interactive tests have been converted to spec/requests/homeworks_request_spec.rb.
RSpec.describe 'Teacher sets homework', :default_creates, :js, type: :system do
  let(:classroom) { create(:classroom, subject:, school: teacher.school) }
  let(:lesson) { create(:lesson, topic:) }
  let(:ten_questions) { create_list(:question, 10, lesson:, topic: lesson.topic) }

  before do
    sign_in teacher
    setup_subject_database
    create(:enrollment, classroom:, user: teacher)
    topic
  end

  context 'when creating a homework' do
    it 'allows you to create a homework' do
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      create_homework
      expect(page).to have_css('tr.homework-data td', text: topic.name)
    end

    it 'attaches the homework to the correct classroom' do
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      create_homework
      visit(classroom_path(classroom.id))
      expect(page).to have_css('tr.homework-data td', text: topic.name)
    end
  end

  context 'when viewing a homework' do
    let(:homework) { create(:homework, classroom:) }

    before do
      create_list(:enrollment, 9, classroom:)
      visit(homework_path(homework))
    end

    it 'allows the teacher to delete the homework' do
      click_link('Delete Homework')
      expect(page).to have_no_css('tr.homework-data td', text: topic.name)
    end
  end

  context 'when setting a lesson homework' do
    let(:nine_questions) { create_list(:question, 9, lesson:, topic: lesson.topic) }
    let(:second_topic) { create(:topic, subject:) }
    let(:lesson_different_topic) { create(:lesson, topic: second_topic) }
    let(:ten_questions_different_topic) do
      create_list(:question, 10, lesson: lesson_different_topic, topic: second_topic)
    end

    before { lesson }

    it 'allows you to set a lesson specific homework' do
      ten_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      create_homework_for_lesson
      expect(page).to have_css('tr.homework-data td', text: lesson.title)
    end

    it 'only shows you lessons that have at least 10 questions' do
      nine_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      select topic.name, from: 'Topic'
      expect(page).to have_no_text(lesson.title)
    end

    it 'only shows lessons when a topic has been selected' do
      ten_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      expect(page).to have_no_text(lesson.title)
    end

    it 'only shows lessons for the topic selected' do
      ten_questions
      ten_questions_different_topic
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      select topic.name, from: 'Topic'
      expect(page).to have_no_text(lesson_different_topic.title)
    end
  end

  context 'when viewing a homework for a lesson' do
    before do
      ten_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
    end

    it 'shows the lesson the homework was created for if available' do
      create_homework_for_lesson
      find_by_id('flash-notice')
      expect(page).to have_text(lesson.title)
    end

    it 'shows the topic the lesson was created for' do
      create_homework
      find_by_id('flash-notice')
      expect(page).to have_text(topic.name)
    end
  end
end
