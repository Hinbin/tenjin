# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User takes a quiz", :default_creates, :js do
  let(:lesson) { create(:lesson, topic: topic) }

  context "when answering a multiple choice question" do
    let(:correct_answer_text) { "Correct answer" }
    let(:incorrect_answer_text) { "Incorrect answer" }
    let!(:question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      question.answers.find_by(correct: true).update!(text: correct_answer_text)
      create(:answer, question: question, correct: false, text: incorrect_answer_text)
      create_list(:answer, 2, question: question, correct: false)
      sign_in student
      navigate_to_quiz
    end

    context "with a lesson" do
      let!(:question) { create(:question, topic: topic, lesson: lesson) }

      before { visit quizzes_path }

      context "with no content" do
        let(:lesson) { create(:lesson, topic: topic, category: "no_content", video_id: "") }

        it "does not show the lesson title" do
          expect(page).to have_no_content(lesson.title)
        end
      end

      context "with video content" do
        it "shows the lesson title" do
          expect(page).to have_content(lesson.title)
        end

        it "shows the lesson video link" # pending — no positive assertion for .videoLink
      end
    end

    it "does not show a lesson video" do
      expect(page).to have_no_css(".videoLink")
    end

    it "displays the question text" do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "hides the next question button" do
      expect(page).to have_css(".next-button", visible: :hidden)
    end

    context "when an answer button is clicked" do
      before { find("button.question-button:first-of-type").click }

      it "reveals the next question button" do
        expect(page).to have_css(".next-button", visible: :visible)
      end

      it "disables all answer buttons" do
        expect(page).to have_css(".question-button[disabled]", visible: :visible)
      end
    end

    context "when the chosen answer is correct" do
      before { find("button", text: correct_answer_text).click }

      it "marks the chosen answer as correct" do
        expect(page).to have_css("button.correct-answer", text: correct_answer_text)
      end

      it "shows a check icon" do
        expect(page).to have_css("i.fa-check")
      end
    end

    context "when the chosen answer is incorrect" do
      before { find("button", text: incorrect_answer_text).click }

      it "marks the chosen answer as incorrect" do
        expect(page).to have_css("button.incorrect-answer", text: incorrect_answer_text)
      end

      it "highlights the correct answer" do
        expect(page).to have_css("button.correct-answer", text: correct_answer_text)
      end

      it "shows a times icon" do
        expect(page).to have_css("i.fa-times")
      end
    end

    context "when flagging unfair questions" do
      it "shows a flag icon" do
        expect(page).to have_css("i.fa-flag")
      end

      it "flags a question" do
        find("i.fa-flag").click
        expect(page).to have_css("i.fas.fa-flag").and have_content("You have flagged this question as unfair")
      end

      context "when the question has already been flagged" do
        let!(:flagged_question) { create(:flagged_question, user: student, question: question) }

        before { page.refresh }

        it "shows the question as flagged" do
          expect(page).to have_css("i.fas.fa-flag")
        end

        it "unflags a question" do
          find("i.fas.fa-flag").click
          expect(page).to have_css("i.far.fa-flag")
        end
      end
    end
  end

  context "with multiple questions" do
    let!(:question) { create(:question, topic: topic) }
    let!(:second_question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      sign_in student
      navigate_to_quiz
    end

    it "allows the user to advance through each question" do
      find("button.question-button:first-of-type").click
      find(".next-button").click
      find("button.question-button:first-of-type").click
      find(".next-button").click
      expect(page).to have_content("Finished!")
    end
  end

  context "when the question text includes an image" do
    before do
      image = create_file_blob(filename: "computer-science.jpg", content_type: "image/jpeg")
      html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>Test message</p>)
      create(:question, topic: topic, question_text: html)

      setup_subject_database
      sign_in student
      navigate_to_quiz
    end

    it "displays the image" do
      expect(page).to have_css('img[src$="computer-science.jpg"]')
    end
  end

  context "with a short answer question" do
    let(:correct_answer_text) { "Paris" }
    let(:incorrect_response) { FFaker::Lorem.word }

    before do
      setup_subject_database
      sign_in student
    end

    context "with a single question" do
      let!(:question) { create(:short_answer_question, topic: topic) }

      before do
        question.answers.find_by(correct: true).update!(text: correct_answer_text)
        navigate_to_quiz
      end

      context "with a lesson" do
        let!(:question) { create(:short_answer_question, topic: topic, lesson: lesson) }

        before { visit quizzes_path }

        it "shows the lesson title" do
          expect(page).to have_content(lesson.title)
        end

        it "shows the lesson video link" # pending — no positive assertion for .videoLink
      end

      it "does not show a lesson video" do
        expect(page).to have_no_css(".videoLink")
      end

      it "displays the question text" do
        expect(page).to have_content(question.question_text.to_plain_text)
      end

      context "when answering correctly" do
        before { fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return) }

        it "reveals the next question button" do
          expect(page).to have_css(".next-button", visible: :visible)
        end

        it "marks the answer as correct" do
          expect(page).to have_css("#shortAnswerButton.correct-answer")
        end

        it "shows a check icon" do
          expect(page).to have_css("i.fa-check")
        end
      end

      context "when the response matches the correct answer but with different case" do
        before { fill_in("shortAnswerText", with: correct_answer_text.upcase).native.send_keys(:return) }

        it "marks the answer as correct" do
          expect(page).to have_css("#shortAnswerButton.correct-answer")
        end
      end

      context "when answering incorrectly" do
        before { fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return) }

        it "marks the answer as incorrect" do
          expect(page).to have_css("#shortAnswerButton.incorrect-answer")
        end

        it "shows the correct answer" do
          find(".incorrect-answer")
          expect(find_field("shortAnswerText", disabled: true).value).to eq(correct_answer_text)
        end

        it "shows a times icon" do
          expect(page).to have_css("i.fa-times")
        end
      end

      context "with multiple correct answers" do
        let!(:second_correct_answer) { create(:answer, question: question, correct: true) }

        it "shows all correct answers when the response is wrong" do
          fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
          find(".incorrect-answer")
          expect(find_field("shortAnswerText", disabled: true).value).to include(correct_answer_text)
            .and include(second_correct_answer.text)
        end

        it "accepts either correct answer" do
          fill_in("shortAnswerText", with: second_correct_answer.text).native.send_keys(:return)
          expect(page).to have_css("#shortAnswerButton.correct-answer")
        end
      end
    end

    context "when tracking quiz progress" do
      let!(:question) { create(:short_answer_question, topic: topic) }
      let!(:second_question) { create(:short_answer_question, topic: topic) }

      before do
        question.answers.find_by(correct: true).update!(text: correct_answer_text)
        second_question.answers.find_by(correct: true).update!(text: correct_answer_text)
        navigate_to_quiz
      end

      context "when checking multipliers" do
        it "shows the current multiplier" do
          expect(page).to have_css("#multiplier", text: 1)
        end

        context "when a multiplier threshold is reached" do
          let!(:multiplier) { create(:multiplier, score: 1, multiplier: 2) }

          it "moves the multiplier after advancing to the next question" do
            fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
            find(".next-button").click
            expect(page).to have_css("#multiplier", text: 2)
          end

          it "updates the multiplier straight after answering" do
            fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
            expect(page).to have_css("#multiplier", text: 2)
          end
        end
      end

      it "increases the percentage complete after answering" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        find(".next-button").click
        expect(find(".progress-bar")[:"aria-valuenow"].to_f).to be > 0
      end

      it "increases the streak when the answer is correct" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        find(".next-button").click
        expect(page).to have_css("#streak", text: 1)
      end

      it "resets the streak to 0 when the answer is incorrect" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        find(".next-button").click
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        expect(page).to have_css("#streak", text: 0)
      end

      it "updates the streak immediately after answering" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        expect(page).to have_css("#streak", text: 1)
      end

      it "shows the number of correct answers so far" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        find(".next-button").click
        expect(page).to have_css("#answeredCorrect", text: 1)
      end

      it "updates the correct answer count immediately" do
        fill_in("shortAnswerText", with: correct_answer_text).native.send_keys(:return)
        expect(page).to have_css("#answeredCorrect", text: 1)
      end
    end
  end
end
