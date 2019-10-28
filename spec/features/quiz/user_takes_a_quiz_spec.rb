# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User takes a quiz', type: :feature, js: true, default_creates: true do
  let(:lesson) { create(:lesson, topic: topic) }

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

    it 'shows a lesson video if one is present' do
      question.lesson = lesson
      visit quizzes_path
      expect(page).to have_content(lesson.title)
    end

    it 'only shows a lesson video if one is present' do
      expect(page).to have_no_css('.videoLink')
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
      expect(page).to have_css('button#' + correct_response_selector + '.correct-answer')
    end

    it 'indicates if the answer I gave was wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('button#' + incorrect_response_selector + '.incorrect-answer')
    end

    it 'indicates the correct answer if the answer I gave was wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('button#' + correct_response_selector + '.correct-answer')
    end

    it 'uses icons to show which questions are right' do
      find(id: correct_response_selector).click
      expect(page).to have_css('i.fa-check')
    end

    it 'uses icons to show which questions are wrong' do
      find(id: incorrect_response_selector).click
      expect(page).to have_css('i.fa-times')
    end

    context 'when flagging unfair questions' do
      let(:flagged_question) { create(:flagged_question, user: student, question: question) }

      it 'shows an option to flag a problem with a question' do
        expect(page).to have_css('i.fa-flag')
      end

      it 'allows me to flag a question' do
        find(:css, 'i.fa-flag').click
        expect(page).to have_css('i.fas.fa-flag').and have_content('You have flagged this question as unfair')
      end

      it 'shows if I have already flagged a particular question' do
        flagged_question
        visit current_path # refresh page
        expect(page).to have_css('i.fas.fa-flag')
      end

      it 'allows me to unflag a question' do
        flagged_question
        visit current_path # refresh page
        find(:css, 'i.fas.fa-flag').click
        expect(page).to have_css('i.far.fa-flag')
      end
    end
  end

  context 'with more than two quesitons in a quiz' do
    let(:question) { create(:question, topic: topic) }
    let(:next_question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      create(:answer, question: question, correct: true)
      create(:answer, question: next_question, correct: true)
      sign_in student
      navigate_to_quiz
    end

    it 'allows a user to go forward to the next question' do
      find(class: 'question-button').click
      find(class: 'next-button').click
      find(class: 'question-button').click
      find(class: 'next-button').click
      expect(page).to have_content('Finished!')
    end
  end

  context 'when dealing with images' do
    before do
      image = create_file_blob(filename: 'computer-science.jpg', content_type: 'image/jpg')
      html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>Test message</p>)
      question = create(:question, topic: topic, question_text: html)

      setup_subject_database
      create(:answer, question: question, correct: true)
      sign_in student
      navigate_to_quiz
    end

    it 'displays images for a question' do
      expect(page).to have_css('img[src$="computer-science.jpg"]')
    end
  end

  context 'when answering a short answer question' do
    let(:question) { create(:short_answer_question, topic: topic) }
    let(:incorrect_response) { FFaker::Lorem.word }
    let(:correct_response) { Answer.first.text }
    let(:second_correct_answer) { create(:answer, question: question, correct: true) }

    before do
      setup_subject_database
      create(:answer, question: question, correct: true)
      sign_in student
      navigate_to_quiz
    end

    it 'shows a lesson video if one is present' do
      question.lesson = lesson
      visit quizzes_path
      expect(page).to have_content(lesson.title)
    end

    it 'only shows a lesson video if one is present' do
      expect(page).to have_no_css('.videoLink')
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
      find('.incorrect-answer')
      expect(find_field('shortAnswerText', disabled: true).value).to eq(correct_response)
    end

    it 'gives the correct answers if I responded incorrectly to a question that has multiple answers' do
      second_correct_answer
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      find('.incorrect-answer')
      expect(find_field('shortAnswerText', disabled: true).value).to include(correct_response)
        .and include(second_correct_answer.text)
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
        expect(page).to have_css('#multiplier', text: 1)
      end

      it 'moves multipliers if I have enough questions right' do
        create(:multiplier, score: 1, multiplier: 2)
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(page).to have_css('#multiplier', text: 2)
      end

      it 'updates my multiplier straight after answering' do
        create(:multiplier, score: 1, multiplier: 2)
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        expect(page).to have_css('#multiplier', text: 2)
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
        expect(page).to have_css('#streak', text: 4)
      end

      it 'reset my streak to 0 if I am wrong' do
        fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(page).to have_css('#streak', text: 0)
      end

      it 'updates my streak straight away after answering' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        expect(page).to have_css('#streak', text: 4)
      end

      it 'shows the number correct I have so far' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(page).to have_css('#answeredCorrect', text: 1)
      end

      it 'updates my number correct straight after answering' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        expect(page).to have_css('#answeredCorrect', text: 1)
      end
    end
  end
end
