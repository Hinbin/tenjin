require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User creates a quiz', type: :feature, js: true do
  include_context 'default_creates'

  context 'when picking a subject' do
    let(:subject_cs) { create(:computer_science) }
    let(:classroom_cs) { create(:classroom, subject: subject_cs, school: school) }

    it 'shows a subject image when there is one available' do
      create(:subject_map, school: school, subject: subject_cs)
      create(:enrollment, classroom: classroom_cs, user: student)
      log_in
      expect(page).to have_css('img[src*=computer-science]')

    end

    it 'shows a default subject image if there is not a specific one' do
      setup_subject_database
      log_in
      expect(page).to have_css('img[src*=default-subject]')
    end

    it 'takes me to the correct topic select page' do
      setup_subject_database
      log_in
      find(class: 'subject-carousel-item-image').click
      expect(page).to have_content(/Select topic/i)
    end
  end

  context 'when selecting a topic' do
    let(:topic) { create(:topic, subject: Subject.first) }

    before do
      setup_subject_database
      create(:question, topic: topic)
      log_in
    end

    it 'allows me to select a topic' do
      visit(new_quiz_path(params: { subject: subject.name }))
      find(:xpath, '//select/option[1]')
      expect(page).to have_select('quiz_picked_topic', options: ['Lucky Dip', Topic.first.name])
    end

    it 'creates a quiz on the correct topic' do
      navigate_to_quiz
      expect(page).to have_current_path(%r{quizzes/[0-9]*})
    end
  end

  context 'when creating a quiz straight from a challenge' do
    it 'creates the quiz in the correct topic'
    it 'allows me to answer a question' #bug
  end
end
