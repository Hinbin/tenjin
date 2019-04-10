require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User takes a quiz', type: :feature, js: true do
  include_context 'default_creates'

  context 'when answering a multiple choice question' do
    let(:question) { create(:question, topic: topic) }
    let(:correct_response) { Answer.where(correct: true).first }
    let(:correct_response_selector) { ('response-' + correct_response.id.to_s).to_s }
    let(:incorrect_response_selector) { ('response-' + (correct_response.id - 1).to_s).to_s }

    before do
      setup_subject_database
      create_list(:answer, 3, question: question)
      create(:answer, question: question, correct: true)
      sign_in student
      navigate_to_quiz
    end

    it 'displays the question text' do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it 'allows me to respond to a question' do
      first(class: 'question-button').click
      expect(page).to have_selector('.next-button', visible: true)
    end

    it 'disables all other buttons when I attempt to answer' do
      first(class: 'question-button').click
      expect(page).to have_css('.question-button[disabled]', visible: true)
    end

    it 'hides the next question button before answering' do
      expect(page).to have_selector('.next-button', visible: false)
    end

    it 'indicates if the answer I gave was right' do
      find(id: correct_response_selector).click
      expect(page).to have_css('div#' + correct_response_selector + '.correct-answer')
    end

    it 'indicates if the answer I gave was wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('div#' + incorrect_response_selector + '.incorrect-answer')
    end

    it 'indicates the correct answer if the answer I gave was wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('div#' + correct_response_selector + '.correct-answer')
    end

    it 'uses icons to show which questions are right' do
      find(id: correct_response_selector).click
      expect(page).to have_css('i.fa-check')
    end

    it 'uses icons to show which questions are wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('i.fa-times')
    end

    it 'displays images for a question'
  end

  context 'when answering a short answer question' do
    let(:question) { create(:short_answer_question, topic: topic) }
    let(:incorrect_response) { FFaker::Lorem.word }
    let(:correct_response) { Answer.first.text }
    let(:second_correct_answer) { create(:answer, question: question, correct: true)}

    before do
      setup_subject_database
      create(:answer, question: question, correct: true)
      sign_in student
      navigate_to_quiz
    end

    it 'displays the question text' do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it 'allows me to respond to a question' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(page).to have_selector('.next-button', visible: true)
    end

    it 'indicates if the answer I gave was right' do
      fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
      expect(page).to have_css('#shortAnswerButton.correct-answer')
    end

    it 'ignores case in the answers I give' do
      fill_in('shortAnswerText', with: correct_response.upcase).native.send_keys(:return)
      expect(page).to have_css('#shortAnswerButton.correct-answer')
    end

    it 'indicates if the answer I gave was wrong' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(page).to have_css('#shortAnswerButton.incorrect-answer')
    end

    it 'gives the correct answer if I responded incorrectly' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(find_field('shortAnswerText', disabled: true).value).to eq(correct_response)
    end

    it 'gives the correct answers if I responded incorrectly to a question that has multiple answers' do
      second_correct_answer
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(find_field('shortAnswerText', disabled: true).value).to include(correct_response).and include(second_correct_answer.text)
    end

    it 'allows multiple answers for a single word question' do
      second_correct_answer
      fill_in('shortAnswerText', with: second_correct_answer.text).native.send_keys(:return)
      expect(page).to have_css('#shortAnswerButton.correct-answer')
    end

    it 'uses icons to show when I am right' do
      fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
      expect(page).to have_css('i.fa-check')
    end

    it 'uses icons to show when I am wrong' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(page).to have_css('i.fa-times')
    end

    it 'shows the next question button if there is no correct answer returned' do
      Answer.first.destroy
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(page).to have_selector('.next-button', visible: true)
    end

    context 'when checking my multipliers' do
      before do
        create(:asked_question, question: question, quiz: Quiz.first, user: student)
      end

      it 'shows the current multiplier' do
        expect(page).to have_text('Multiplier: 1x')
      end

      it 'moves multipliers if I have enough questions right' do
        create(:multiplier, score: 1, multiplier: 2)
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(page).to have_text('Multiplier: 2x')
      end
    end

    context 'when answering a question' do
      let(:quiz) { Quiz.first }

      before do
        create(:asked_question, question: question, quiz: quiz, user: student)
        create(:asked_question, question: question, quiz: quiz, user: student)
        quiz.streak = 3
        quiz.save
      end

      it 'increases the percentage complete' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(find('.progress-bar')[:'aria-valuenow'].to_f).to be > 0
      end

      it 'increases my streak if I am right' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(page).to have_text('Streak: 4')
      end

      it 'reset my streak to 0 if I am wrong' do
        fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
        first(class: 'next-button').click

        expect(page).to have_text('Streak: 0')
      end
    end
  end
end
