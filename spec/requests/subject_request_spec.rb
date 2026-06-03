# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subjects', type: :request, default_creates: true do
  let(:new_subject_name) { FFaker::Lorem.word }
  let(:ten_questions_for_subject) { create_list(:question, 10, topic:) }
  let(:five_asked_questions_this_week) { create_list(:asked_question, 5, question:) }
  let(:seven_asked_questions_previously) { create(:question_statistic, question:, number_asked: 7) }

  before { sign_in super_admin }

  context 'when viewing all subjects' do
    before { subject }

    it 'allows an admin to view subjects' do
      get subjects_path
      expect(response.body).to include(subject.name)
    end

    it 'shows how many questions are in each subject' do
      ten_questions_for_subject
      get subjects_path
      expect(response.body).to include('10')
    end

    it 'shows how many asked questions there are for each subject this week' do
      five_asked_questions_this_week
      get subjects_path
      expect(response.body).to include('5')
    end

    it 'totals this week and previous weeks question data' do
      five_asked_questions_this_week
      seven_asked_questions_previously
      get subjects_path
      html = Capybara.string(response.body)
      expect(html).to have_css("tr#subject-#{subject.id} td.asked_questions", text: '12')
    end

    it 'only counts questions for this week' do
      five_asked_questions_this_week
      seven_asked_questions_previously
      get subjects_path
      html = Capybara.string(response.body)
      expect(html).to have_css("tr#subject-#{subject.id} td.asked_questions_this_week", text: '5')
    end

    it 'shows how many asked questions there are for each subject overall' do
      seven_asked_questions_previously
      get subjects_path
      expect(response.body).to include('7')
    end

    it 'allows an admin to create a subject' do
      post subjects_path, params: { subject: { name: new_subject_name } }
      follow_redirect!
      expect(response.body).to include(new_subject_name)
    end
  end

  context 'when managing an individual subject' do
    before { subject }

    it 'allows admin to visit a subject page' do
      get subject_path(subject)
      html = Capybara.string(response.body)
      expect(html).to have_css('.display-4', text: subject.name)
    end

    it 'allows admin to change name of the subject' do
      patch subject_path(subject), params: { subject: { name: new_subject_name } }
      follow_redirect!
      html = Capybara.string(response.body)
      expect(html).to have_css('#subject_name', text: new_subject_name)
    end
  end
end
