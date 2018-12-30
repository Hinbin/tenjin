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
    let(:topic) { create(:topic, subject: Subject.first) }

    before do
      setup_subject_database
      create(:question, topic: topic)
      log_in
    end

    it 'allows me to select a topic' do
      visit('quizzes/new?subject=Computer+Science')
      find(:xpath, '//select/option[1]')
      expect(page).to have_select('quiz_picked_topic', options: ['Lucky Dip', Topic.first.name])
    end

    it 'creates a quiz on the correct topic' do
      navigate_to_quiz
      expect(page).to have_current_path(%r{quizzes/[0-9]*})
    end
  end
end
