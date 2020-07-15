# frozen_string_literal: true

RSpec.describe 'Author edits a question', type: :system, js: true, default_creates: true do
  let(:author) { create(:question_author, subject: subject) }
  let(:question) { create(:question, topic: topic) }
  let(:lesson) { create(:lesson, topic: topic) }
  let(:new_topic_name) { FFaker::Lorem.word }

  def add_answer
    click_link('Add Answer')
    find('#answer-text-1')
    all('.text-answer').last.set("#{answer_text}\n")
    click_button('Save Question')
  end

  def switch_to_student_account
    wait_for_ajax
    sign_out author
    sign_in student
    visit new_quiz_path(subject: topic.subject.name)
  end

  def switch_and_create_quiz
    switch_to_student_account
    click_button('Create Quiz')
  end

  before do
    setup_subject_database
    sign_in author
  end

  context 'when assigning default lessons' do
    before do
      lesson
      create(:question, topic: topic, lesson: lesson)
    end

    it 'assigns a default lesson to a topic' do
      visit(topic_questions_questions_path(topic_id: topic))
      select lesson.title, from: 'Default Lesson'
      switch_and_create_quiz
      expect(page).to have_css(".videoLink[src^=\"https://www.youtube.com/embed/#{lesson.video_id}\"]")
    end
  end

  it 'only shows a default lesson when needed' do
    question
    visit(dashboard_path)
    switch_and_create_quiz
    expect(page).to have_no_css('.videoLink')
  end

  context 'when adding or removing questions' do
    let(:flagged_question) { create_list(:flagged_question, 5, question: question) }

    before do
      question
      flagged_question
      visit(questions_path)
      click_link(question.topic.name)
    end

    it 'allows you to create a question' do
      click_link('Add Question')
      expect(page).to have_css('#questionEditor')
    end

    it 'allows you to delete a question' do
      visit(question_path(question))
      page.accept_confirm { click_link('Delete Question') }
      expect(page).to have_no_css('.question-row')
    end

    it 'shows the number of flags a question has' do
      expect(page).to have_css("tr#question-#{question.id} td.flags", exact_text: '5')
    end
  end

  context 'when adding or removing topics' do
    before do
      visit(questions_path)
    end

    it 'allows you to create a topic' do
      click_link('Add Topic')
      expect(page).to have_content('Delete Topic')
    end

    it 'allows you to disable a topic' do
      click_link('Add Topic')
      page.accept_confirm { click_link('Delete Topic') }
      expect(page).to have_no_css('.topic-row')
    end

    it 'prevents disabled topics from showing when taking a quiz' do
      visit(topic_questions_questions_path(topic_id: topic))
      page.accept_confirm { click_link('Delete Topic') }
      find('div', exact_text: subject.name, count: 2)
      switch_to_student_account
      expect(page).to have_no_css('option', text: topic.name)
    end
  end

  context 'when visiting the topic index page' do
    before do
      question
      visit(questions_path)
      click_link(question.topic.name)
    end

    it 'allows you to edit a topic name' do
      fill_in('Topic Name', with: new_topic_name)
      find('label', text: 'Topic Name').click
      switch_to_student_account
      navigate_to_quiz
      expect(page).to have_content(new_topic_name)
    end

    it 'shows the quesitons for a topic' do
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it 'allows you to edit a question' do
      click_link(question.question_text.to_plain_text)
      expect(page).to have_current_path(question_path(question))
    end
  end

  context 'when visiting the subject index page' do
    before do
      question
      visit(questions_path)
    end

    it 'shows each subject' do
      expect(page).to have_content(question.topic.subject.name)
    end

    it 'shows the links for a topic' do
      expect(page).to have_link(question.topic.name)
    end
  end

  context 'when editing a question' do
    let(:answer_text) { FFaker::Lorem.word }
    let(:answer) { create(:answer, question: question) }
    let(:answer_id) { 'answer-text-0' }
    let(:answer_check_id) { 'answer-check-0' }

    it 'shows the content of the question' do
      visit(question_path(question))
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it 'allows you to delete the question' do
      visit(question_path(question))
      page.accept_confirm { click_link('Delete Question') }
      expect(page).to have_no_content(question.question_text.to_plain_text)
    end

    context 'when showing a multiple choice question' do
      before do
        create_list(:answer, 3, correct: false, question: question)
        visit(question_path(question))
        find_by_id('select-question-type').click
        find('option', text: 'Multiple').click
      end

      it 'allows you to set an answer as correct' do
        find('table', id: 'table-answers')
        find('input', id: answer_check_id).click
        visit(question_path(question))
        expect(page).to have_css('#' + answer_check_id)
      end

      it 'only saves if I have selected a correct answer' do
        Answer.all.update_all(correct: false)
        visit(question_path(question))
        find('table', id: 'table-answers')
        click_button('Save Question')
        expect(page).to have_content('Question must have at least one correct answer')
      end

      it 'allows you to add an answer' do
        visit(question_path(question))
        add_answer
        switch_and_create_quiz
        expect(page).to have_content(answer_text)
      end

      it 'allows you to edit an existing answer' do
        visit(question_path(question))
        fill_in(answer_id, with: "#{answer_text}\n")
        switch_and_create_quiz
        expect(page).to have_content(answer_text)
      end

      it 'allows you to delete an existing answer' do
        create_list(:answer, 2, question: question)
        visit(question_path(question))
        expect { first('.btn-danger').click }.to change(Answer, :count).by(-1)
      end
    end

    context 'when showing a short answer question' do
      let(:question) { create(:question, question_type: 'short_answer', topic: topic) }

      before do
        visit(question_path(question))
        find_by_id('select-question-type').click
        wait_for_ajax
        find('option', text: 'Short answer').click
        wait_for_ajax
        find('table', id: 'table-answers')
      end

      def add_new_answer
        click_link('Add Answer')
        all('.text-answer').last.set("#{answer_text}\n")
        click_button('Save Question')
      end

      it 'does not let you modify if the answer is correct' do
        expect(page).to have_no_content('Correct?')
      end

      it 'changes any existing answers for the question to be correct' do
        expect(Answer.first.correct).to eq(true)
      end

      it 'allows me to save without saying I need to select a correct answer' do
        click_button('Save Question')
        expect(page).to have_content('Question successfully updated')
      end

      it 'saves every answer as correct' do
        add_new_answer
        switch_and_create_quiz
        fill_in('shortAnswerText', with: "#{answer_text}\n")
        expect(page).to have_css('.correct-answer')
      end
    end

    context 'when showing a boolean question' do
      before do
        visit(question_path(question))
        find_by_id('select-question-type').click
        find('option', text: 'Boolean').click
        find('table', id: 'table-answers')
      end

      it 'creates two answers, true and false' do
        expect(page).to have_selector('input[value="True"]').and have_selector('input[value="False"]')
      end

      it 'allows you to set an answer as correct' do
        find('input', id: answer_check_id).click
        wait_for_ajax
        switch_and_create_quiz
        find("#response-#{Answer.last.id}").click
        expect(page).to have_css("#response-#{Answer.last.id}.correct-answer")
      end

      it 'does not allow you to remove an answer' do
        expect(page).to have_no_link('Remove')
      end
    end

    context 'when assigning a lesson' do
      before do
        lesson
        create_list(:answer, 3, question: question)
      end

      it 'allows you to assign a lesson to the question' do
        visit(question_path(question))
        select lesson.title, from: 'select-lesson'
        click_button('Save Question')
        switch_and_create_quiz
        expect(page).to have_content(lesson.title)
      end
    end

    context 'when resetting question flags' do
      before do
        create(:flagged_question, question: question)
      end

      it 'shows the number of question flags' do
        visit(question_path(question))
        expect(page).to have_content('Flags: 1')
      end

      it 'resets flags when presssing the button' do
        visit(question_path(question))
        click_link('Reset Question Flags')
        expect(page).to have_content('Flags: 0')
      end
    end
  end
end
