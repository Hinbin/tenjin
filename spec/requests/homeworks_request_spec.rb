# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Homeworks', type: :request, default_creates: true do
  let(:classroom) { create(:classroom, subject:, school: teacher.school) }
  let(:homework) { create(:homework, classroom:) }

  before do
    sign_in teacher
    create(:enrollment, classroom:, user: student)
    create(:enrollment, classroom:, user: teacher)
    create(:multiplier)
    topic
  end

  context 'when creating a homework' do
    it 'alerts you if you have not got a classroom id' do
      get new_homework_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  context 'when viewing a homework' do
    before do
      create_list(:enrollment, 9, classroom:)
    end

    it 'shows all the students that are assigned to the homework' do
      get homework_path(homework)
      html = Capybara.string(response.body)
      expect(html).to have_css('tr.student-row', count: 10)
    end

    it 'shows the percentage of students that have completed the homework' do
      HomeworkProgress.first.update_attribute(:completed, true)
      get homework_path(homework)
      expect(response.body).to include('10%')
    end

    it 'allows the teacher to delete the homework' do
      delete homework_path(homework)
      expect(response).to redirect_to(classroom_path(homework.classroom))
    end

    it 'shows the progress towards completion' do
      HomeworkProgress.first.update_attribute(:progress, 50)
      get homework_path(homework)
      expect(response.body).to include('50%')
    end
  end
end
