RSpec.describe 'Teacher visits the dashboard', type: :feature, js: true, default_creates: :true do
  
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }

  before do
    setup_subject_database

    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
  end

  context 'when logging in as a teacher' do
    it 'shows which classes they are currently assigned to' do
      visit(dashboard_path)
      expect(page).to have_content(classroom.name)
    end

    it 'shows a link to homework in the nav bar' do
      expect(page).to have_css('a[href=' + homeworks_path + ']')
    end

    it 'does not show challenge points' do
      expect(page).to have_no_content('i.fa-star')
    end
  end

end
