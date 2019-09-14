RSpec.describe 'School admin sets up classrooms', type: :feature, js: true, default_creates: true do

  context 'when configuring classrooms' do
    let(:classroom) { create(:classroom, school: school) }
    let(:subject) { create(:subject) }

    before do
      classroom
      sign_in school_admin
    end

    it 'shows which classrooms have been retreived from Wonde' do
      visit(classrooms_path)
      expect(page).to have_content(classroom.name)
    end

    it 'allows me to set a subject to this classroom' do
      subject
      visit(classrooms_path)
      select subject.name, from: 'subject'
      visit(classrooms_path)
      expect(page).to have_content(subject.name)
    end

    it 'allows me to visit the classroom assignment page' do
      visit(classrooms_path)
      expect(page).to have_css('a', text: 'Setup Classrooms')
    end

    it 'tells me when I need to sync the school'do
      subject
      visit(classrooms_path)
      select subject.name, from: 'subject'
      expect(page).to have_content('School sync required. Click here to start')
    end

  end
end
