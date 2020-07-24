# frozen_string_literal: true

RSpec.describe 'Super manages subjects', type: :system, js: true, default_creates: true do
  let(:ten_questions_for_subject) { create_list(:question, 10, topic: topic) }
  let(:five_asked_questions_this_week) { create_list(:asked_question, 5, question: question) }
  let(:seven_asked_questions_previously) { create(:question_statistic, question: question, number_asked: 7) }

  context 'when viewing all subjects' do
    before do
      sign_in super_admin
      subject
    end

    it 'allows an admin to view subjects' do
      visit(subjects_path)
      expect(page).to have_content(subject.name)
    end

    it 'shows how many questions are in each subject' do
      ten_questions_for_subject
      visit(subjects_path)
      expect(page).to have_content('10')
    end

    it 'shows how many asked questions there are for each subject this week' do
      five_asked_questions_this_week
      visit(subjects_path)
      expect(page).to have_content('5')
    end

    it 'totals this week and previous weeks question data' do
      five_asked_questions_this_week
      seven_asked_questions_previously
      visit(subjects_path)
      expect(page).to have_css('tr#subject-' + subject.id.to_s + ' td.asked_questions', text: '12')
    end

    it 'only counts questions for this week' do
      five_asked_questions_this_week
      seven_asked_questions_previously
      visit(subjects_path)
      expect(page).to have_css('tr#subject-' + subject.id.to_s + ' td.asked_questions_this_week', text: '5')
    end

    it 'shows how many asked questions there are for each subject overall' do
      seven_asked_questions_previously
      visit(subjects_path)
      expect(page).to have_content('7')
    end
  end

  context 'when managing an individual subject' do
    let(:new_subject_name) { FFaker::Lorem.word }

    before do
      sign_in super_admin
      subject
    end

    it 'allows admin to visit a subject page' do
      visit(subjects_path)
      click_link(subject.name)
      expect(page).to have_css('.display-4', text: subject.name)
    end

    it 'allows admin to change name of the subject' do
      visit(subject_path(subject))
      fill_in('subject[name]', with: new_subject_name)
      click_button('Update')
      expect(page).to have_css('#subject_name', text: new_subject_name)
    end

    it 'allows an admin to create a subject'
    it 'allows an admin to delete a subject'
    it 'deletes questions for a subject'
    it 'required the admin to type in the subject name'
    it 'allows you to upload questions for the subject'
    it 'allows you to download questions for the subject'
  end
end
