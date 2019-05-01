RSpec.describe 'Teacher sets homework', type: :feature, js: true do
  include_context 'default_creates'

  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:flatpickr_one_week_from_now) do
    "span.flatpickr-day[aria-label=\"#{(Time.now + 1.week).strftime('%B %-e, %Y')}\"]"
  end

  before do
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
    topic
    sign_in teacher
    visit(new_homework_path(classroom: { classroom_id: classroom.id }))
  end

  context 'when creating a homework' do
    it 'allows you to create a homework' do
      create_homework
      expect { click_button('Set Homework') }.to change(Homework, :count).by(1)
    end

    it 'attaches the homework to the correct classroom' do
      create_homework
      click_button('Set Homework')
      expect(Homework.first.classroom).to eq(classroom)
    end

    it 'alerts you if you have not got a classroom id' do
      visit(new_homework_path)
      expect(page).to have_current_path(dashboard_path)
    end
  end

  context 'when viewing a homework' do
    let(:homework) { create(:homework, classroom: classroom) }

    before do
      create_list(:enrollment, 9, classroom: classroom)
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
      expect { click_link('Delete Homework') }.to change(Homework, :count).by(-1)
    end

    it 'shows the progress towards completion' do
      HomeworkProgress.first.update_attribute(:progress, 50)
      visit(homework_path(homework))
      expect(page).to have_content('50%')
    end
  end
end
