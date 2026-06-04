# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Author edits a question", :default_creates, :js do
  let(:author) { create(:question_author, subject: quiz_subject) }
  let(:question) { create(:question, topic: topic) }

  def add_answer
    click_link("Add Answer")
    find_by_id("answer-text-1")
    all(".text-answer").last.set("#{answer_text}\n")
    click_button("Save Question")
    find(".alert-info", text: "Question successfully updated")
  end

  def save_question
    click_button("Save Question")
    find(".alert-info", text: "Question successfully updated")
  end

  def switch_to_student_account
    click_link("Logout")
    find("button", text: "LOGIN")
    sign_in student
    visit dashboard_path
    find("h3", text: quiz_subject.name.upcase)
    visit new_quiz_path(subject: topic.subject.name)
  end

  def switch_and_create_quiz
    switch_to_student_account
    click_button("Create Quiz")
  end

  before do
    setup_subject_database
    sign_in author
  end

  context "when assigning default lessons" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:lesson_question) { create(:question, topic: topic, lesson: lesson) }

    before { visit(topic_questions_path(topic_id: topic)) }

    it "assigns a default lesson to a topic" do
      select lesson.title, from: "Default Lesson"
      switch_and_create_quiz
      expect(page).to have_css(".videoLink[src^=\"https://www.youtube.com/embed/#{lesson.video_id}\"]")
    end
  end

  context "without a lesson assigned" do
    let!(:question) { create(:question, topic: topic) }

    before { visit(dashboard_path) }

    it "does not show a lesson video" do
      switch_and_create_quiz
      expect(page).to have_no_css(".videoLink")
    end
  end

  context "when checking most flagged questions" do
    let!(:flagged_question) { create(:question, topic: topic, flagged_questions_count: 5) }

    before do
      visit questions_path
      click_link "Most Flagged Questions"
    end

    it "displays flagged questions" do
      expect(page).to have_content(flagged_question.question_text.to_plain_text)
    end
  end

  context "when adding or removing questions" do
    let!(:question) { create(:question, topic: topic) }
    let!(:flagged_question) { create_list(:flagged_question, 5, question: question) }

    before do
      visit(questions_path)
      click_link(question.topic.name)
    end

    it "navigates to the new question form" do
      click_link("Add Question")
      expect(page).to have_css("#questionEditor")
    end

    it "deletes a question" do
      visit(question_path(question))
      page.accept_confirm { click_link("Delete Question") }
      expect(page).to have_no_css(".question-row")
    end

    it "shows the number of flags a question has" do
      within "#question-#{question.id}" do
        expect(page).to have_css("[tabulator-field='flags']", exact_text: "5")
      end
    end
  end

  context "when adding or removing topics" do
    before do
      visit(questions_path)
    end

    it "creates a topic" do
      click_link("Add Topic")
      expect(page).to have_content("Delete Topic")
    end

    it "disables a topic" do
      click_link("Add Topic")
      page.accept_confirm { click_link("Delete Topic") }
      expect(page).to have_no_css(".topic-row")
    end

    it "prevents disabled topics from showing when taking a quiz" do
      visit(topic_questions_path(topic_id: topic))
      page.accept_confirm { click_link("Delete Topic") }
      expect(page).to have_css("div", exact_text: quiz_subject.name, count: 1)
      switch_to_student_account
      expect(page).to have_no_css("option", text: topic.name)
    end
  end

  context "when visiting the topic index page" do
    let!(:question) { create(:question, topic: topic) }
    let(:new_topic_name) { FFaker::Lorem.word }

    before do
      visit(questions_path)
      click_link(question.topic.name)
    end

    it "edits a topic name" do
      fill_in("Topic Name", with: new_topic_name)
      find("label", text: "Topic Name").click
      switch_to_student_account
      navigate_to_quiz
      expect(page).to have_content(new_topic_name)
    end

    it "shows the questions for a topic" do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "navigates to the question edit page" do
      click_link(question.question_text.to_plain_text)
      expect(page).to have_current_path(question_path(question))
    end
  end

  context "when visiting the subject index page" do
    let!(:question) { create(:question, topic: topic) }

    before { visit(questions_path) }

    it "shows each subject" do
      expect(page).to have_content(question.topic.subject.name)
    end

    it "shows the links for a topic" do
      expect(page).to have_link(question.topic.name)
    end
  end

  context "when editing a question" do
    let(:answer_text) { FFaker::Lorem.word }
    let(:answer_check_id) { "answer-check-0" }

    before { visit(question_path(question)) }

    it "shows the content of the question" do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it "deletes the question" do
      page.accept_confirm { click_link("Delete Question") }
      expect(page).to have_no_content(question.question_text.to_plain_text)
    end

    context "when showing a multiple choice question" do
      let(:answer_id) { "answer-text-0" }

      before do
        create_list(:answer, 3, correct: false, question: question)
        visit(question_path(question))
        find_by_id("select-question-type").click
        find("option", text: "Multiple").click
      end

      it "sets an answer as correct" do
        find("table", id: "table-answers")
        find("input", id: answer_check_id).click
        visit(question_path(question))
        expect(page).to have_css("##{answer_check_id}")
      end

      context "with no correct answer selected" do
        before do
          Answer.all.update_all(correct: false)
          visit(question_path(question))
          find("table", id: "table-answers")
        end

        it "requires a correct answer to be selected before saving" do
          click_button("Save Question")
          expect(page).to have_content("Question must have at least one correct answer")
        end
      end

      it "adds an answer" do
        visit(question_path(question))
        add_answer
        switch_and_create_quiz
        expect(page).to have_content(answer_text)
      end

      it "edits an existing answer" do
        visit(question_path(question))
        fill_in(answer_id, with: "#{answer_text}\n")
        save_question
        switch_and_create_quiz
        expect(page).to have_content(answer_text)
      end

      context "with multiple answers" do
        before { create_list(:answer, 2, question: question) }

        it "deletes an existing answer" do
          visit(question_path(question))
          initial_count = all("#table-answers tbody tr").count
          find("#table-answers tr:first-child .btn-danger").click
          expect(page).to have_css("#table-answers tbody tr", count: initial_count - 1)
        end
      end
    end

    context "when showing a short answer question" do
      let!(:question) { create(:question, question_type: "short_answer", topic: topic) }

      before do
        visit(question_path(question))
        find_by_id("select-question-type").click
        find("option", text: "Short answer").click
        find("table", id: "table-answers")
      end

      def add_new_answer
        click_link("Add Answer")
        all(".text-answer").last.set("#{answer_text}\n")
        click_button("Save Question")
        find(".alert-info", text: "Question successfully updated")
      end

      it "does not show the correct answer toggle" do
        expect(page).to have_no_content("Correct?")
      end

      it "saves without requiring a correct answer selection" do
        click_button("Save Question")
        expect(page).to have_content("Question successfully updated")
      end

      it "saves every answer as correct" do
        add_new_answer
        switch_and_create_quiz
        fill_in("shortAnswerText", with: "#{answer_text}\n")
        expect(page).to have_css(".correct-answer")
      end
    end

    context "when showing a boolean question" do
      before do
        visit(question_path(question))
        find_by_id("select-question-type").click
        find("option", text: "Boolean").click
        find("table", id: "table-answers")
      end

      it "creates two answers, true and false" do
        expect(page).to have_css('input[value="True"]').and have_css('input[value="False"]')
      end

      it "sets an answer as correct" do
        find("input", id: answer_check_id).click
        switch_and_create_quiz
        find("#response-#{Answer.last.id}").click
        expect(page).to have_css("#response-#{Answer.last.id}.correct-answer")
      end

      it "does not show a remove answer button" do
        expect(page).to have_no_link("Remove")
      end
    end

    context "when assigning a lesson" do
      let!(:lesson) { create(:lesson, topic: topic) }

      before do
        create_list(:answer, 3, question: question)
        visit(question_path(question))
      end

      it "assigns a lesson to the question" do
        select lesson.title, from: "select-lesson"
        save_question
        switch_and_create_quiz
        expect(page).to have_content(lesson.title)
      end
    end

    context "when resetting question flags" do
      before do
        create(:flagged_question, question: question)
        visit(question_path(question))
      end

      it "shows the number of question flags" do
        expect(page).to have_content("Flags: 1")
      end

      it "resets flags" do
        click_link("Reset Question Flags")
        expect(page).to have_content("Flags: 0")
      end
    end
  end
end
