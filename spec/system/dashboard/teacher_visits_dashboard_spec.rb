# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Teacher visits the dashboard', type: :system, js: true, default_creates: true do
  let(:classroom) { create(:classroom, subject: subject, school: teacher.school) }
  let(:other_classroom) { create(:classroom, school: school) }

  before do
    setup_subject_database
  end

  context 'when logging in as a teacher' do
    before do
      create(:enrollment, classroom: classroom, user: teacher)
      sign_in teacher
    end

    it 'shows which classes they are currently assigned to' do
      visit(dashboard_path)
      expect(page).to have_content(classroom.name)
    end

    it 'allows you to go to a selected classroom' do
      visit(dashboard_path)
      find("tr[data-classroom="#{classroom.id.to_s}"]").click
      expect(page).to have_current_path(classroom_path(classroom))
    end

    it 'allows you to go to set homework for the classroom' do
      visit(dashboard_path)
      click_link('Set Homework')
      expect(page).to have_current_path(new_homework_path(classroom: { classroom_id: classroom.id }))
    end

    it 'shows a link to the classrooms in the nav bar' do
      visit(dashboard_path)
      expect(page).to have_link('Classrooms', href: dashboard_path)
    end

    it 'does not show challenge points' do
      visit(dashboard_path)
      expect(page).to have_no_content('i.fa-star')
    end

    it 'shows other classes in a school with a subject assigned' do
      create(:enrollment, classroom: other_classroom, user: create(:teacher, school: school))
      visit(dashboard_path)
      expect(page).to have_css("#otherClassrooms tr[data-classroom="#{other_classroom.id.to_s}"]")
    end
  end

  context 'when logging in as a school admin' do
    before do
      create(:enrollment, classroom: classroom, user: school_admin)
      sign_in school_admin
    end

    it 'shows a link to the classrooms in the nav bar' do
      visit(dashboard_path)
      expect(page).to have_link('Classrooms', href: dashboard_path)
    end

    it 'shows a link to school admin in the nav bar' do
      visit(dashboard_path)
      expect(page).to have_link('User Admin', href: users_path)
    end
  end
end
