# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Author edits a question", :default_creates, :js do
  let(:author) { create(:question_author, subject: quiz_subject) }
  let(:question) { create(:question, topic: topic) }

  def save_question
    click_button("Save Question")
    find(".alert-info", text: "Question successfully updated")
  end

  def add_answer(text)
    click_link("Add Answer")
    find_by_id("answer-text-1")
    all(".text-answer").last.set("#{text}\n")
    save_question
  end

  def switch_to_student_account
    click_button("Logout")
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

  describe "default lesson assignment" do
    let!(:lesson) { create(:lesson, topic: topic) }
    let!(:lesson_question) { create(:question, topic: topic, lesson: lesson) }

    before { visit(topic_questions_path(topic_id: topic)) }

    it "shows the lesson video on a student quiz" do
      select lesson.title, from: "Default Lesson"
      switch_and_create_quiz
      expect(page).to have_css(".videoLink[src^=\"https://www.youtube.com/embed/#{lesson.video_id}\"]")
    end
  end

  describe "topic without a default lesson" do
    let!(:question) { create(:question, topic: topic) }

    before { visit(dashboard_path) }

    it "shows no lesson video on a student quiz" do
      switch_and_create_quiz
      expect(page).to have_no_css(".videoLink")
    end
  end

  describe "most flagged questions" do
    let!(:flagged_question) { create(:question, topic: topic, flagged_questions_count: 5) }

    before do
      visit questions_path
      click_link "Most Flagged Questions"
    end

    it "lists flagged questions for the subject" do
      expect(page).to have_content(flagged_question.question_text.to_plain_text)
    end
  end

  describe "topic question index" do
    let!(:question) { create(:question, topic: topic) }

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
      page.accept_confirm { click_button("Delete Question") }
      expect(page).to have_no_css(".question-row")
    end

    it "navigates to the question edit page" do
      find("a", text: question.question_text.to_plain_text).trigger("click")
      expect(page).to have_current_path(question_path(question))
    end

    it "renames the topic and reflects it on student quizzes" do
      new_topic_name = FFaker::Lorem.word
      fill_in("Topic Name", with: new_topic_name)
      find("label", text: "Topic Name").click
      switch_to_student_account
      navigate_to_quiz
      expect(page).to have_content(new_topic_name)
    end

    context "with flagged questions" do
      let!(:flagged_questions) { create_list(:flagged_question, 5, question: question) }

      before do
        visit(questions_path)
        click_link(question.topic.name)
      end

      it "shows the flag count for each question" do
        within "#question-#{question.id}" do
          expect(page).to have_css("[tabulator-field='flags']", exact_text: "5")
        end
      end
    end
  end

  describe "topic management" do
    before { visit(questions_path) }

    it "creates a topic" do
      click_link("Add Topic")
      expect(page).to have_button("Delete Topic")
    end

    it "disables a topic" do
      click_link("Add Topic")
      page.accept_confirm { click_button("Delete Topic") }
      expect(page).to have_no_css(".topic-row")
    end

    it "hides disabled topics from student quiz creation" do
      visit(topic_questions_path(topic_id: topic))
      page.accept_confirm { click_button("Delete Topic") }
      expect(page).to have_css("div", exact_text: quiz_subject.name, count: 1)
      switch_to_student_account
      expect(page).to have_no_css("option", text: topic.name)
    end
  end

  describe "question editor" do
    let(:answer_text) { FFaker::Lorem.word }
    let(:answer_check_id) { "answer-check-0" }

    before { visit(question_path(question)) }

    it "deletes the question" do
      page.accept_confirm { click_button("Delete Question") }
      expect(page).to have_no_content(question.question_text.to_plain_text)
    end

    describe "multiple choice question" do
      let(:answer_id) { "answer-text-0" }

      before do
        create_list(:answer, 3, correct: false, question: question)
        visit(question_path(question))
        select "Multiple", from: "select-question-type"
        find("table", id: "table-answers")
      end

      it "marks an answer as correct" do
        find("input", id: answer_check_id).click
        visit(question_path(question))
        expect(page).to have_css("##{answer_check_id}")
      end

      it "adds an answer that appears on a student quiz" do
        visit(question_path(question))
        add_answer(answer_text)
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

      context "with no correct answer selected" do
        before do
          question.answers.update_all(correct: false)
          visit(question_path(question))
          find("table", id: "table-answers")
        end

        it "rejects saving without a correct answer" do
          click_button("Save Question")
          expect(page).to have_content("Question must have at least one correct answer")
        end
      end

      context "with extra answers" do
        before { create_list(:answer, 2, question: question) }

        it "deletes an existing answer" do
          visit(question_path(question))
          expect(page).to have_css("#table-answers tbody tr", count: 6)
          find("#table-answers tr:first-child .btn-danger").click
          expect(page).to have_css("#table-answers tbody tr", count: 5)
        end
      end
    end

    describe "short answer question" do
      let!(:question) { create(:short_answer_question, topic: topic) }

      before do
        visit(question_path(question))
        select "Short answer", from: "select-question-type"
        find("table", id: "table-answers")
      end

      def add_short_answer(text)
        click_link("Add Answer")
        all(".text-answer").last.set("#{text}\n")
        save_question
      end

      it "hides the correct answer toggle" do
        expect(page).to have_no_content("Correct?")
      end

      it "saves without requiring a correct answer selection" do
        click_button("Save Question")
        expect(page).to have_content("Question successfully updated")
      end

      it "marks every saved answer as correct" do
        add_short_answer(answer_text)
        switch_and_create_quiz
        fill_in("shortAnswerText", with: answer_text).native.send_keys(:return)
        expect(page).to have_css(".correct-answer")
      end
    end

    describe "boolean question" do
      before do
        visit(question_path(question))
        select "Boolean", from: "select-question-type"
        find("table", id: "table-answers")
      end

      it "marks an answer as correct on a student quiz" do
        find("input", id: answer_check_id).click
        switch_and_create_quiz
        find("#response-#{Answer.last.id}").click
        expect(page).to have_css("#response-#{Answer.last.id}.correct-answer")
      end

      it "hides the remove answer button" do
        expect(page).to have_no_link("Remove")
      end
    end

    describe "lesson assignment" do
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

    describe "flag reset" do
      before do
        create(:flagged_question, question: question)
        visit(question_path(question))
      end

      it "resets the flag count to zero" do
        expect(page).to have_content("Flags: 1")
        click_button("Reset Question Flags")
        expect(page).to have_content("Flags: 0")
      end
    end
  end
end
