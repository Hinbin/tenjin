# frozen_string_literal: true

RSpec.describe 'User visits a classroom', type: :system, js: true, default_creates: true do
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:homework) { create(:homework, classroom: classroom) }

  before do
    topic
    setup_subject_database
    create(:enrollment, classroom: classroom, user: teacher)
    sign_in teacher
  end

  context 'when looking at the classroom information' do
    before do
      visit(classroom_path(classroom))
    end

    it 'shows the name of the classroom' do
      expect(page).to have_content(classroom.name)
    end

    it 'shows the name of the students' do
      expect(page).to have_content(student.forename)
    end

    it 'allows me to create a homework' do
      click_link('Set Homework')
      expect(page).to have_current_path(new_homework_path(classroom: { classroom_id: classroom.id }))
    end

    it 'takes me to a homework that I have clicked on' do
      homework
      visit(classroom_path(classroom))
      find(:css, "tr[data-controller='homeworks'][data-id='#{homework.id}']").click
      expect(page).to have_current_path(homework_path(homework))
    end

    it 'shows the correct percentage of homeworks completed' do
      homework
      create_list(:homework_progress, 3, homework: homework, completed: false)
      create_list(:homework_progress, 6, homework: homework, completed: true)
      visit(classroom_path(classroom))
      expect(page).to have_css('td', text: '60%')
    end

    context 'when looking at the student table' do
      let(:second_homework) { HomeworkProgress.joins(:homework).order('homeworks.due_date desc').second }
      let(:different_classroom) { create(:classroom, school: school) }

      it 'shows the last 5 homeworks for the classroom' do
        create_list(:enrollment, 10, classroom: classroom)
        create_list(:homework, 10, classroom: classroom)
        visit(classroom_path(classroom))
        expect(page).to have_css("tr[data-id='#{student.id}'] i.fa-times", count: 5)
      end

      it 'allows the user to search the student table' do
        create_list(:enrollment, 32, classroom: classroom)
        visit(classroom_path(classroom))
        find('#students-table_filter input').set("#{student.forename} #{student.surname}")
        expect(page).to have_css('.student-data', count: 1)
      end

      it 'shows a completed homework in the correct place' do
        create_list(:homework, 5, classroom: classroom)
        second_homework.update_attribute(:completed, true)
        visit(classroom_path(classroom))
        expect(page).to have_css("tr[data-id='#{student.id}'] td:nth-child(5) i:nth-child(2).fa-check")
      end

      it 'does not show homeworks for another classroom' do
        create(:homework, classroom: different_classroom)
        expect(page).to have_no_css('i.fa-times')
      end

      it 'only loads the data table once after going back in the browser' do
        visit(classroom_path(classroom))
        click_link('Set Homework')
        page.go_back
        expect { page.accept_alert }.to raise_error(Capybara::ModalNotFound)
      end

      it 'paginates the number of homeworks, 5 per page' do
        create_list(:homework, 20, classroom: classroom)
        visit(classroom_path(classroom))
        expect(page).to have_css('.homework-data', count: 5)
      end

      it 'allows me to reset a password' do
        visit(classroom_path(classroom))
        find(:css, '#resetPasswordCheck').set(true)
        click_link('Reset Password')
        expect(page).to have_no_link('Reset Password').and have_css('.new-password')
      end

      it 'hides reset password buttons by defulat' do
        visit(classroom_path(classroom))
        expect(page).to have_no_link('Reset Password')
      end

      it 'has a working reset password toggle' do
        visit(classroom_path(classroom))
        find(:css, '#resetPasswordCheck').set(true)
        within '#students-table' do
          expect(page).to have_link('Reset Password')
        end
      end
    end
  end

  it 'does not let me view the classroom as a student' do
    sign_in student
    visit(classroom_path(classroom))
    expect(page).to have_current_path(root_path)
  end

  it 'does not show the search box twice after going back' do
    visit(classroom_path(classroom))
    click_link('Set Homework')
    find('section#set_homework')
    page.go_back
    expect(page).to have_css('input[type="search"]', count: 1)
  end

end
