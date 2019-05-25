RSpec.describe 'Teacher views a student record', type: :feature, js: true do
  include_context 'default_creates'

  let(:second_classroom) { create(:classroom, school: school) }
  let(:homework_different_class) { create(:homework, classroom: second_classroom, topic: topic) }
  let(:enrollment_different_class) { create(:enrollment, user: student, classroom: second_classroom) }

  context 'when visiting a students record' do
    before do
      sign_in teacher
      create(:enrollment, user: student, classroom: classroom)
      create(:enrollment, user: teacher, classroom: classroom)
      homework
    end

    it 'opens the student record webpage' do
      visit(user_path(student))
      expect(page).to have_current_path(user_path(student))
    end

    it 'shows uncompleted homeworks' do
      visit(user_path(student))
      expect(page).to have_content(homework.topic.name).and have_css('i.fa-times')
    end

    it 'shows recently completed homeworks' do
      HomeworkProgress.all.update_all(completed: true)
      visit(user_path(student))
    end

    it 'only shows the homeworks for the classes the teacher belongs to' do
      enrollment_different_class
      homework_different_class
      visit(user_path(student))
      expect(page).to have_no_css("tr[data-homework='#{homework_different_class.id}'")
    end
  end
end
