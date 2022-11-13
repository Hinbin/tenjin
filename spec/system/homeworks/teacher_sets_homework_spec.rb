# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Teacher sets homework', type: :system, js: true, default_creates: true do
  let(:classroom) { create(:classroom, subject:, school: teacher.school) }
  let(:flatpickr_one_week_from_now) do
    "span.flatpickr-day[aria-label=\"#{(Time.now + 1.week).strftime('%B %-e, %Y')}\"]"
  end
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

    it 'alerts you if you have not got a classroom id' do
      visit(new_homework_path)
      expect(page).to have_current_path(dashboard_path)
    end
  end

  context 'when viewing a homework' do
    let(:homework) { create(:homework, classroom:) }

    before do
      create_list(:enrollment, 9, classroom:)
      visit(homework_path(homework))
    end

    it 'shows all the students that are assigned to the homework' do
      expect(page).to have_css('tr.student-row', count: 10)
    end

    it 'shows the percentage of students that have completed the homework' do
      HomeworkProgress.first.update_attribute(:completed, true)
      visit(homework_path(homework))
      expect(page).to have_content('10%')
    end

    it 'allows the teacher to delete the homework' do
      click_link('Delete Homework')
      expect(page).to have_no_css('tr.homework-data td', text: topic.name)
    end

    it 'shows the progress towards completion' do
      HomeworkProgress.first.update_attribute(:progress, 50)
      visit(homework_path(homework))
      expect(page).to have_content('50%')
    end
  end

  context 'when setting a lesson homework' do
    let(:nine_questions) { create_list(:question, 9, lesson:, topic: lesson.topic) }
    let(:second_topic) { create(:topic, subject:) }
    let(:lesson_different_topic) { create(:lesson, topic: second_topic) }
    let(:ten_questions_different_topic) do
      create_list(:question, 10, lesson: lesson_different_topic, topic: second_topic)
    end

    before do
      lesson
    end

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
      expect(page).to have_no_content(lesson.title)
    end

    it 'only shows lessons when a topic has been selected' do
      ten_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      expect(page).to have_no_content(lesson.title)
    end

    it 'only shows lessons for the topic selected' do
      ten_questions
      ten_questions_different_topic
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
      select topic.name, from: 'Topic'
      expect(page).to have_no_content(lesson_different_topic.title)
    end
  end

  context 'when viewing a homework for a lesson' do
    before do
      ten_questions
      visit(new_homework_path(classroom: { classroom_id: classroom.id }))
    end

    it 'shows the lesson the homework was created for if available' do
      create_homework_for_lesson
      find_by_id('flash-notice') # homework view page
      expect(page).to have_content(lesson.title)
    end

    it 'shows the topic the lesson was created for' do
      create_homework
      find_by_id('flash-notice') # homework view page
      expect(page).to have_content(topic.name)
    end
  end
end
