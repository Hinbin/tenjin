# frozen_string_literal: true

RSpec.describe 'User attempts a challenge', type: :system, js: true, default_creates: true do
  before do
    setup_subject_database
    sign_in student
  end

  def click_through_quiz
    first(class: 'question-button').click
    first(class: 'next-button').click
    first(class: 'question-button').click
    first(class: 'next-button').click
  end

  context 'when looking at the challenges' do
    let(:challenge_single_question) do
      create(:challenge, topic: topic, challenge_type: 'number_correct',
                         number_required: 1, end_date: Time.now + 1.hour)
    end
    let(:challenge_daily) do
      create(:challenge, challenge_type: 'number_of_points', daily: true, topic: topic,
                         number_required: 1, end_date: Time.now + 1.hour)
    end
    let(:second_subject) { create(:subject) }
    let(:second_topic) { create(:topic, subject: second_subject) }
    let(:challenge_two) { create(:challenge, topic: create(:topic, subject: subject)) }
    let(:question) { create(:question, topic: topic) }
    let(:progressed_challenge) { create(:challenge_progress, user: student, challenge: challenge_one, progress: 70) }
    let(:completed_challenge) do
      create(:challenge_progress, user: student, challenge: challenge_one, progress: 100,
                                  completed: true)
    end
    let(:quiz) { create(:new_quiz) }

    context 'when completing a num. points challenge' do
      before do
        challenge_single_question
        question
      end

      it 'links you to the correct quiz when clicked' do
        visit(dashboard_path)
        find(:css, '#challenge-table tbody tr:nth-child(1)').click
        expect(page).to have_css('p', exact_text: challenge_single_question.topic.name)
      end

      it 'allows me to answer a question after creating a quiz from a challenge' do # turbolinks bug
        visit(dashboard_path)
        find(:css, '#challenge-table tbody tr:nth-child(1)').click
        first(class: 'question-button').click
        expect(page).to have_text('Next Question')
      end

      it 'lets me complete a number of points required challenge' do
        visit(dashboard_path)
        find(:css, '#challenge-table tbody tr:nth-child(1)').click
        first(class: 'question-button').click
        first(class: 'next-button').click
        expect(page).to have_css('i.fa-check')
      end
    end

    context 'when completing a daily challenge' do
      before do
        challenge_daily
      end

      it 'lets me complete a number of points in the day challenge' do
        create(:question, topic: create(:topic, subject: subject))
        visit(dashboard_path)
        find(:css, '#challenge-table tbody tr:nth-child(1)').click
        click_through_quiz
        expect(page).to have_css('i.fa-check')
      end
    end
  end
end
