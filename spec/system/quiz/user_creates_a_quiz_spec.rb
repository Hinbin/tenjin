# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User creates a quiz', default_creates: true, js: true, type: :system do
  context 'when picking a subject' do
    let(:subject_cs) { create(:computer_science) }
    let(:classroom_cs) { create(:classroom, subject: subject_cs, school:) }

    it 'shows a subject image when there is one available' do
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

  context 'when creating two quizzes in quick succession' do
    before do
      setup_subject_database
      create_list(:answer, 3, question:)
      sign_in student
      navigate_to_quiz
      visit(dashboard_path)
      visit(new_quiz_path(subject: subject.name))
      select Topic.last.name, from: 'quiz_topic_id'
      click_button('Create Quiz')
    end

    it 'prevents you from taking a quiz if 40 seconds have not passed' do
      expect(page).to have_current_path(dashboard_path)
    end

    it 'says how long they need to wait to create another quiz' do
      expect(page).to have_content('You need to wait')
    end
  end

  context 'when creating a quiz for the same topic multiple times' do
    let(:user_topic_score) { TopicScore.where(user: student, topic:).first.score }
    let(:two_quizzes_started) { create(:usage_statistic, user: student, topic:, quizzes_started: 2) }
    let(:three_quizzes_started) { create(:usage_statistic, user: student, topic:, quizzes_started: 3) }

    before do
      setup_subject_database
      question
      sign_in student
    end

    it 'allows you to score points for the first attempt' do
      navigate_to_quiz
      first(class: 'question-button').click
      find('.correct-answer')
      expect(user_topic_score).to eq(1)
    end

    it 'allows you to score points for the third attempt' do
      two_quizzes_started
      navigate_to_quiz
      first(class: 'question-button').click
      find('.correct-answer')
      expect(user_topic_score).to eq(1)
    end

    it 'always allows you to score with a lucky dip' do
      three_quizzes_started
      navigate_to_lucky_dip
      expect(page).to have_no_content('not counting')
    end

    context 'when you should not be allowed to score' do
      let(:three_quizzes_started) { create(:usage_statistic, user: student, topic:, quizzes_started: 3) }

      before do
        three_quizzes_started
        navigate_to_quiz
      end

      it 'does not allow you to score points for the fourth attempt' do
        create(:topic_score, user: student, topic:, score: 3)
        first(class: 'question-button').click
        find('.correct-answer')
        expect(user_topic_score).to eq(3)
      end

      it 'informs the user they cannot currently score leaderboard points for this quiz' do
        expect(page).to have_content('not counting')
      end
    end
  end

  context 'when selecting a topic' do
    let(:topic) { create(:topic, subject: Subject.first) }
    let(:customisation) { create(:dashboard_customisation, value: 'orange') }
    let(:active_customisation) { create(:active_customisation, user: student, customisation:) }

    before do
      setup_subject_database
      create(:question, topic:)
      log_in
    end

    it 'allows me to select a topic' do
      visit(new_quiz_path(params: { subject: subject.name }))
      find(:xpath, '//select/option[1]')
      expect(page).to have_select('quiz_topic_id', options: ['Lucky Dip', Topic.first.name])
    end

    it 'creates a quiz on the correct topic' do
      navigate_to_quiz
      expect(page).to have_current_path(%r{quizzes/[0-9]*})
    end

    it 'has a separator of the correct colour' do
      active_customisation
      visit(new_quiz_path(params: { subject: subject.name }))
      expect(page).to have_css("hr[style*='#{active_customisation.customisation.value}'")
    end
  end
end
