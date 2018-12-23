require 'rails_helper'

RSpec.describe QuizzesController, type: :controller do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school) }

  before do
    sign_in student
  end

  describe 'GET #new' do
    it 'shows the topic select page for a valid subject' do
      enrollment = create(:enrollment, school: school, user: student)
      get :new, params: { subject: enrollment.classroom.subject.name }
      expect(response).to render_template('quizzes/select_topic', 'layouts/application')
    end

    it 'prevents me selecting a topic for a subject I am not allowed to use' do
      create(:enrollment, school: school, user: student)
      different_subject = create(:classroom, school: school)
      
      get :new, params: { subject: different_subject.subject.name }
      expect(response).to redirect_to dashboard_path
    end


    it 'redirects to dashboard for a subject that does not exist' do
      get :new, params: { subject: 'NOSUBJECT' }
      expect(response).to redirect_to dashboard_path
    end
 
  end
end
