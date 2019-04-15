RSpec.describe 'User visits a classroom', type: :feature, js: true, default_creates: :true do

  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:homework) { create(:homework, classroom: classroom) }

  before do
    topic
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
    visit(classroom_path(classroom))
  end

  context 'when looking at the classroom information' do
    it 'shows the name of the classroom' do
      expect(page).to have_content(classroom.name)
    end

    it 'shows the name of the students' do
      expect(page).to have_content(student.forename)
    end

    it 'allows me to create a homework' do
      click_link('Set Homework')
      expect(current_path).to eq(new_homework_path)
    end

    it 'takes me to a homework that I have clicked on' do
      homework
      visit(classroom_path(classroom))
      find(:css, 'tr[data-homework="' + homework.id.to_s + '"]' ).click
      expect(current_path).to eq(homework_path(homework))
    end
  end

  it 'does not let me view the classroom as a student' do
    sign_in student
    visit(classroom_path(classroom))
    expect(current_path).to eq(root_path)
  end

  it 'shows a chart showing progress completion of the last 6 homeworks set'

end
