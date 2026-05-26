# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User takes a quiz", :default_creates, :js do
  let(:lesson) { create(:lesson, topic: topic) }

  context "when answering a multiple choice question" do
    let(:correct_answer_text) { "Correct answer" }
    let(:incorrect_answer_text) { "Incorrect answer" }
    let(:question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      question.answers.find_by(correct: true).update!(text: correct_answer_text)
      create(:answer, question: question, correct: false, text: incorrect_answer_text)
      create_list(:answer, 2, question: question, correct: false)
      sign_in student
      navigate_to_quiz
    end

    context "with a lesson" do
      let(:question) { create(:question, topic: topic, lesson: lesson) }

      before { visit quizzes_path }

      context "with no content" do
        let(:lesson) { create(:lesson, topic: topic, category: "no_content", video_id: "") }

        it "doesn't show the lesson title" do
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

    it "only shows a lesson video if one is present" do
      expect(page).to have_no_css(".videoLink")
    end

    it "displays the question text" do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "allows responding to a question" do
      find("button.question-button:first-of-type").click
      expect(page).to have_css(".next-button", visible: :visible)
    end

    it "disables all other buttons when answering" do
      find("button.question-button:first-of-type").click
      expect(page).to have_css(".question-button[disabled]", visible: :visible)
    end

    it "hides the next question button before answering" do
      expect(page).to have_css(".next-button", visible: :hidden)
    end

    it "shows the answer as correct when right" do
      find("button", text: correct_answer_text).click
      expect(page).to have_css("button.correct-answer", text: correct_answer_text)
    end

    it "shows the answer as incorrect when wrong" do
      find("button", text: incorrect_answer_text).click
      expect(page).to have_css("button.incorrect-answer", text: incorrect_answer_text)
    end

    it "highlights the correct answer when the wrong answer is chosen" do
      find("button", text: incorrect_answer_text).click
      expect(page).to have_css("button.correct-answer", text: correct_answer_text)
    end

    it "uses a check icon when the answer is correct" do
      find("button", text: correct_answer_text).click
      expect(page).to have_css("svg.fa-check")
    end

    it "uses a times icon when the answer is incorrect" do
      find("button", text: incorrect_answer_text).click
      expect(page).to have_css("svg.fa-times")
    end

    context "when flagging unfair questions" do
      it "shows an option to flag a problem with a question" do
        expect(page).to have_css("svg.fa-flag")
      end

      it "flags a question" do
        find("svg.fa-flag").click
        expect(page).to have_css('svg.fa-flag[data-prefix="fas"]').and have_content("You have flagged this question as unfair")
      end

      context "when the question has already been flagged" do
        let!(:flagged_question) { create(:flagged_question, user: student, question: question) }

        before { page.refresh }

        it "shows the question is flagged" do
          expect(page).to have_css('svg.fa-flag[data-prefix="fas"]')
        end

        it "unflags a question" do
          find('svg.fa-flag[data-prefix="fas"]').click
          expect(page).to have_css('svg.fa-flag[data-prefix="far"]')
        end
      end
    end
  end

  context "with more than two questions" do
    let!(:question) { create(:question, topic: topic) }
    let!(:next_question) { create(:question, topic: topic) }

    before do
      setup_subject_database
      sign_in student
      navigate_to_quiz
    end

    it "allows a user to go forward to the next question" do
      find("button.question-button:first-of-type").click
      find(".next-button").click
      find("button.question-button:first-of-type").click
      find(".next-button").click
      expect(page).to have_content("Finished!")
    end
  end

  context "when dealing with images" do
    before do
      image = create_file_blob(filename: "computer-science.jpg", content_type: "image/jpeg")
      html = %(<action-text-attachment sgid="#{image.attachable_sgid}"></action-text-attachment><p>Test message</p>)
      create(:question, topic: topic, question_text: html)

      setup_subject_database
      sign_in student
      navigate_to_quiz
    end

    it "displays images for a question" do
      expect(page).to have_css('img[src$="computer-science.jpg"]')
    end
  end

  context "with a short answer question" do
    let(:correct_answer_text) { "Paris" }
    let(:incorrect_response) { FFaker::Lorem.word }
    let(:correct_response) { correct_answer_text }

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
        let(:question) { create(:short_answer_question, topic: topic, lesson: lesson) }

        before { visit quizzes_path }

        it "shows a lesson video if one is present" do
          expect(page).to have_content(lesson.title)
        end

        it "shows the lesson video link" # pending — no positive assertion for .videoLink
      end

      it "doesn't show a lesson video" do
        expect(page).to have_no_css(".videoLink")
      end

      it "displays the question text" do
        expect(page).to have_content(question.question_text.to_plain_text)
      end

      it "allows responding to a question" do
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        expect(page).to have_css(".next-button", visible: :visible)
      end

      it "shows the answer as correct when right" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        expect(page).to have_css("#shortAnswerButton.correct-answer")
      end

      it "ignores case when checking the answer" do
        fill_in("shortAnswerText", with: correct_response.upcase).native.send_keys(:return)
        expect(page).to have_css("#shortAnswerButton.correct-answer")
      end

      it "shows the answer as incorrect when wrong" do
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        expect(page).to have_css("#shortAnswerButton.incorrect-answer")
      end

      it "shows the correct answer when wrong" do
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        find(".incorrect-answer")
        expect(find_field("shortAnswerText", disabled: true).value).to eq(correct_response)
      end

      context "with multiple correct answers" do
        let!(:second_correct_answer) { create(:answer, question: question, correct: true) }

        it "shows all correct answers when wrong" do
          fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
          find(".incorrect-answer")
          expect(find_field("shortAnswerText", disabled: true).value).to include(correct_response)
            .and include(second_correct_answer.text)
        end

        it "allows multiple answers for a single word question" do
          fill_in("shortAnswerText", with: second_correct_answer.text).native.send_keys(:return)
          expect(page).to have_css("#shortAnswerButton.correct-answer")
        end
      end

      it "uses a check icon when the answer is correct" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        expect(page).to have_css("svg.fa-check")
      end

      it "uses a times icon when the answer is incorrect" do
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        expect(page).to have_css("svg.fa-times")
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
            fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
            find(".next-button").click
            expect(page).to have_css("#multiplier", text: 2)
          end

          it "updates the multiplier straight after answering" do
            fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
            expect(page).to have_css("#multiplier", text: 2)
          end
        end
      end

      it "increases the percentage complete after answering" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        find(".next-button").click
        expect(find(".progress-bar")[:"aria-valuenow"].to_f).to be > 0
      end

      it "increases the streak when the answer is correct" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        find(".next-button").click
        expect(page).to have_css("#streak", text: 1)
      end

      it "resets the streak to 0 when the answer is incorrect" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        find(".next-button").click
        fill_in("shortAnswerText", with: incorrect_response).native.send_keys(:return)
        expect(page).to have_css("#streak", text: 0)
      end

      it "updates the streak immediately after answering" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        expect(page).to have_css("#streak", text: 1)
      end

      it "shows the number of correct answers so far" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        find(".next-button").click
        expect(page).to have_css("#answeredCorrect", text: 1)
      end

      it "updates the correct answer count immediately" do
        fill_in("shortAnswerText", with: correct_response).native.send_keys(:return)
        expect(page).to have_css("#answeredCorrect", text: 1)
      end
    end
  end
end
