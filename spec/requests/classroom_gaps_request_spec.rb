# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Classroom gap analysis', :default_creates, type: :request do
  before { create(:enrollment, school: school, classroom: classroom, user: student) }

  describe 'GET /classrooms/gap_analysis' do
    before { create(:enrollment, school: school, classroom: classroom, user: teacher) }

    it 'lists the teacher\'s classes with an engagement summary' do
      sign_in teacher

      get gap_analysis_classrooms_path

      expect(response).to have_http_status(:ok)
      body = Capybara.string(response.body)
      expect(body).to have_text('Gap Analysis')
      expect(body).to have_text(classroom.name)
      expect(body).to have_link('View Gap Analysis', href: gaps_classroom_path(classroom))
    end

    it 'does not list classes the teacher cannot analyse' do
      sign_in create(:teacher)

      get gap_analysis_classrooms_path

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_no_text(classroom.name)
    end
  end

  describe 'GET /classrooms/:id/gaps' do
    it 'renders the gap analysis for a teacher in the same school' do
      sign_in teacher

      get gaps_classroom_path(classroom)

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_text('Gap analysis')
    end

    it 'redirects a teacher from another school' do
      sign_in create(:teacher)

      get gaps_classroom_path(classroom)

      expect(response).to redirect_to(root_path)
    end

    it 'redirects a student' do
      sign_in student

      get gaps_classroom_path(classroom)

      expect(response).not_to have_http_status(:ok)
    end
  end

  describe 'GET /classrooms/:id/gaps/student/:student_id' do
    it 'renders the per-student drill for an enrolled pupil' do
      sign_in teacher

      get student_gap_classroom_path(classroom, student_id: student.id)

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_text('Personal gap report')
    end

    it 'cannot reach a pupil who is not enrolled in the class' do
      sign_in teacher
      outsider = create(:student, school: school)

      expect { get student_gap_classroom_path(classroom, student_id: outsider.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
