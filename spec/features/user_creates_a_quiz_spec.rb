require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User creates a quiz', :vcr, type: :feature, js: true do
  include_context 'api_data'
  include_context 'wonde_test_data'

  context 'when picking a subject' do
    it 'takes me to the correct topic select page' do
      setup_subject_database
      log_in
      find(class: 'subject-carousel-item-image').click
      expect(page).to have_content(/Select topic/i)
    end
  end

  context 'when selecting a topic' do
    before do
      setup_question_database
      log_in
    end

    it 'allows me to select a topic' do
      visit('quizzes/new?subject=Computer+Science')
      find(:xpath, '//select/option[1]')
      expect(page).to have_select('quiz_picked_topic', options: ['Lucky Dip', 'TestTopic'])
    end

    it 'creates a quiz on the correct topic' do
      navigate_to_quiz
      expect(page).to have_current_path(%r{quizzes/[0-9]*})
    end

    it 'prevents me selecting a topic for a subject I am not allowed to use' do
      visit('quizzes/new?subject=History')
      expect(page).to have_current_path(/dashboard/)
    end
  end
end
