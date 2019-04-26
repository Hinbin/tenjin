RSpec.describe 'Teacher visits the dashboard', type: :feature, js: true, default_creates: true do
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }

  before do
    setup_subject_database

    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
    visit(dashboard_path)
  end

  context 'when logging in as a teacher' do
    it 'shows which classes they are currently assigned to' do
      expect(page).to have_content(classroom.name)
    end

    it 'allows you to go to a selected classroom' do
      find('tr[data-classroom="' + classroom.id.to_s + '"]').click
      expect(page).to have_current_path(classroom_path(classroom))
    end

    it 'shows a link to the classrooms in the nav bar' do
      expect(page).to have_link('Classrooms', href: dashboard_path)
    end

    it 'does not show challenge points' do
      expect(page).to have_no_content('i.fa-star')
    end
  end
end
