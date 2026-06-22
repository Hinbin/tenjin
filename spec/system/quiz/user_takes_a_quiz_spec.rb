# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe 'User takes a quiz', :default_creates, :js, type: :system do
  let(:lesson) { create(:lesson, topic:) }

  context 'when answering a multiple choice question' do
    let(:question) { create(:question, topic:) }
    let(:correct_response) { Answer.where(correct: true).first }

    # Anti-cheat hides the real answers.id: button ids are now per-quiz tokens (Quiz::AnswerToken), so
    # we locate answer buttons by their visible text instead of by id.
    def answer_button(answer)
      find('button.multiple-choice-button', text: answer.text)
    end

    before do
      setup_subject_database
      create_list(:answer, 3, question:, correct: false)
      sign_in student
      navigate_to_quiz
    end

    context 'with a lesson' do
      let(:question) { create(:question, topic:, lesson:) }
      let(:no_content_lesson) { create(:lesson, topic:, category: 'no_content', video_id: '') }

      it 'shows a lesson video if one is present' do
        question.lesson = lesson
        visit quizzes_path
        expect(page).to have_text(lesson.title)
      end

      it 'only shows a lesson with content' do
        question.update_attribute(:lesson, no_content_lesson)
        visit quizzes_path
        expect(page).to have_no_text(lesson.title)
      end
    end

    context 'when selecting a response' do
      let(:incorrect_response) { question.answers.where(correct: false).first }

      it 'only shows a lesson video if one is present' do
        expect(page).to have_no_css('.videoLink')
      end

      it 'displays the question text' do
        expect(page).to have_text(question.question_text.to_plain_text)
      end

      it 'allows me to respond to a question' do
        first(class: 'question-button').click
        expect(page).to have_css('.next-button', visible: :visible)
      end

      it 'disables all other buttons when I attempt to answer' do
        first(class: 'question-button').click
        expect(page).to have_css('.question-button[disabled]', visible: :visible)
      end

      it 'hides the next question button before answering' do
        expect(page).to have_css('.next-button', visible: :hidden)
      end

      it 'indicates if the answer I gave was right' do
        answer_button(correct_response).click
        expect(page).to have_css('button.multiple-choice-button.correct-answer', text: correct_response.text)
      end

      it 'indicates if the answer I gave was wrong' do
        answer_button(incorrect_response).click
        expect(page).to have_css('button.multiple-choice-button.incorrect-answer', text: incorrect_response.text)
      end

      it 'indicates the correct answer if the answer I gave was wrong' do
        answer_button(incorrect_response).click
        expect(page).to have_css('button.multiple-choice-button.correct-answer', text: correct_response.text)
      end

      it 'uses icons to show which questions are right' do
        answer_button(correct_response).click
        expect(page).to have_css('i.fa-check')
      end

      it 'uses icons to show which questions are wrong' do
        answer_button(incorrect_response).click
        expect(page).to have_css('i.fa-times')
      end

      it 'shows the author explanation after I answer' do
        question.update!(explanation: 'Because the binary place values add up to ten.')
        answer_button(incorrect_response).click
        expect(find_by_id('answerFeedback')).to have_text('Because the binary place values add up to ten.')
      end
    end

    context 'when flagging unfair questions' do
      let(:flagged_question) { create(:flagged_question, user: student, question:) }

      it 'shows an option to flag a problem with a question' do
        expect(page).to have_css('i.fa-flag')
      end

      it 'allows me to flag a question' do
        find('button[title="Flag unfair question"]').click
        expect(page).to have_css('i.fas.fa-flag')
                    .and have_text('You have flagged this question as unfair')
      end

      it 'shows if I have already flagged a particular question' do
        flagged_question
        visit quiz_path(Quiz.first)
        expect(page).to have_css('i.fas.fa-flag')
      end

      it 'allows me to unflag a question' do
        flagged_question
        visit quiz_path(Quiz.first)
        find('button[title="Flag unfair question"]').click
        expect(page).to have_css('i.far.fa-flag')
      end
    end
  end

  context 'with more than two quesitons in a quiz' do
    let(:question) { create(:question, topic:) }
    let(:next_question) { create(:question, topic:) }

    before do
      setup_subject_database
      question
      next_question
      sign_in student
      navigate_to_quiz
    end

    it 'allows a user to go forward to the next question' do
      find(class: 'question-button').click
      find(class: 'next-button').click
      find(class: 'question-button').click
      find(class: 'next-button').click
      expect(page).to have_text('This run').and have_button('Play Again')
    end
  end

  context 'when dealing with images' do
    before do
      image = create_file_blob(filename: 'computer-science.jpg', content_type: 'image/jpeg')
      html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>Test message</p>)
      create(:question, topic:, question_text: html)

      setup_subject_database
      sign_in student
      navigate_to_quiz
    end

    it 'displays images for a question' do
      expect(page).to have_css('img[src$="computer-science.jpg"]')
    end
  end

  context 'when answering a short answer question' do
    let(:question) { create(:short_answer_question, topic:) }
    let(:incorrect_response) { FFaker::Lorem.word }
    let(:correct_response) { Answer.first.text }
    let(:second_correct_answer) { create(:answer, question:, correct: true) }

    before do
      setup_subject_database
      question
      sign_in student
      navigate_to_quiz
    end

    context 'with a lesson' do
      let(:question) { create(:short_answer_question, topic:, lesson:) }

      it 'shows a lesson video if one is present' do
        question.lesson = lesson
        visit quizzes_path
        expect(page).to have_text(lesson.title)
      end
    end

    it 'only shows a lesson video if one is present' do
      expect(page).to have_no_css('.videoLink')
    end

    it 'displays the question text' do
      expect(page).to have_text(question.question_text.to_plain_text)
    end

    it 'allows me to respond to a question' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      expect(page).to have_css('.next-button', visible: :visible)
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

    it 'keeps my answer on screen and shows the correct answer if I responded incorrectly' do
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      find_by_id('shortAnswerButton', class: 'incorrect-answer')
      expect(find_field('shortAnswerText', disabled: true).value).to eq(incorrect_response)
      expect(find_by_id('answerFeedback')).to have_text(correct_response)
    end

    it 'shows every correct answer if I responded incorrectly to a question that has multiple answers' do
      second_correct_answer
      fill_in('shortAnswerText', with: incorrect_response).native.send_keys(:return)
      find_by_id('shortAnswerButton', class: 'incorrect-answer')
      expect(find_field('shortAnswerText', disabled: true).value).to eq(incorrect_response)
      expect(find_by_id('answerFeedback')).to have_text(correct_response).and have_text(second_correct_answer.text)
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
      expect(page).to have_css('.next-button', visible: :visible)
    end

    context 'when checking my multipliers' do
      before do
        create(:asked_question, question:, quiz: Quiz.first, user: student)
        # Anti-cheat: an answer within MIN_ANSWER_SECONDS of quiz start is flagged too fast and earns
        # no point, so simulate a human-paced answer to test the normal multiplier path (Quiz::CheckAnswer).
        Quiz.first.update(time_last_answered: 10.seconds.ago)
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
        create(:asked_question, question:, quiz:, user: student)
        create(:asked_question, question:, quiz:, user: student)
        quiz.streak = 3
        # Anti-cheat: an answer within MIN_ANSWER_SECONDS of quiz start is flagged too fast and freezes
        # the streak, so simulate a human-paced answer to test the normal streak path (Quiz::CheckAnswer).
        quiz.time_last_answered = 10.seconds.ago
        quiz.save
      end

      it 'increases the percentage complete' do
        fill_in('shortAnswerText', with: correct_response).native.send_keys(:return)
        first(class: 'next-button').click
        expect(find('.tj-progress__bar')[:'aria-valuenow'].to_f).to be > 0
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
