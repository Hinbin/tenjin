# frozen_string_literal: true

RSpec.describe 'Author edits a question', type: :system, js: true, default_creates: true do

  let(:author) { create(:question_author, subject: subject) }
  let(:question) { create(:question, topic: topic) }
  let(:lesson) { create(:lesson, topic: topic) }
  let(:new_topic_name) { FFaker::Lorem.word }

  def create_and_navigate_to_quiz
    sign_out author
    sign_in student
    create_list(:answer, 3, question: question)
    create(:answer, question: question, correct: true)
    create(:question, topic: topic, lesson: lesson)
    navigate_to_quiz
  end

  def switch_to_student_account
    find('div', exact_text: subject.name, count: 2)
    sign_out author
    sign_in student
    visit new_quiz_path(subject: topic.subject.name)
  end

  before do
    setup_subject_database
    sign_in author
  end

  # it 'assigns a default lesson to a topic' do
  #   lesson
  #   visit(topic_questions_questions_path(topic_id: topic))
  #   select lesson.title, from: 'Default Lesson'
  #   create_and_navigate_to_quiz
  #   expect(page).to have_css(".videoLink[src^=\"http://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
  # end

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

    it 'allows you to delete a question', :focus do
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
      topic
      visit(topic_questions_questions_path(topic_id: topic))
      page.accept_confirm { click_link('Delete Topic') }
      switch_to_student_account
      expect(page).to have_no_css('option', text: topic.name )
    end

    it 'only allows you to delete a topic with no questions' do
      question
      visit(questions_path)
      click_link(Topic.first.name)
      expect(page).to have_no_content('Delete Topic')
    end
  end

  context 'when visiting the topic index page' do
    before do
      question
      visit(questions_path)
      click_link(question.topic.name)
    end

    it 'allows you to edit a topic name' do
      bip_text(question.topic, :name, new_topic_name)
      question.topic.reload
      expect(question.topic.name).to eq(new_topic_name)
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
    let(:answer_id) { 'best_in_place_answer_' + Answer.last.id.to_s + '_text' }

    it 'shows the content of the question' do
      visit(question_path(question))
      expect(page).to have_content(question.question_text.to_plain_text)
    end

    it 'allows you to delete the question' do
      visit(question_path(question))
      page.accept_confirm{ click_link('Delete Question') }
      expect(page).to have_no_content(question.question_text.to_plain_text)
    end

    context 'when showing a multiple choice question' do
      before do
        answer
        visit(question_path(question))
        find_by_id('questionTypeSelect').click
        find('option', text: 'Multiple').click
      end

      it 'allows you to set an answer as correct' do
        find('table', id: 'table-multiple')
        find('span', id: 'best_in_place_answer_' + Answer.first.id.to_s + '_correct').click
        expect(page).to have_css('i.fa-check')
      end

      it 'only saves if I have selected a correct answer' do
        find('table', id: 'table-multiple')
        click_button('Save and return')
        expect(page).to have_content('Please select at least one correct answer')
      end

      it 'only creates a new question if I have selected a correct answer' do
        find('table', id: 'table-multiple')
        click_button('Create another question')
        expect(page).to have_content('Please select at least one correct answer')
      end
    end

    context 'when showing a short answer question' do
      before do
        answer
        visit(question_path(question))
        find_by_id('questionTypeSelect').click
        find('option', text: 'Short answer').click
        find('table', id: 'table-short_answer')
      end

      it 'does not let you modify if the answer is correct' do
        expect(page).to have_no_content('Correct?')
      end

      it 'changes any existing answers for the question to be correct' do
        expect(Answer.first.correct).to eq(true)
      end

      it 'allows me to save without saying I need to select a correct answer' do
        click_button('Save and return')
        expect(page).to have_content(question.topic.name)
      end

      it 'flags any new answers entered as correct' do
        click_link('Add Answer')
        bip_text(Answer.last, :text, answer_text)
        expect(Answer.last.correct).to eq(true)
      end
    end

    context 'when showing to a boolean question' do
      before do
        visit(question_path(question))
        find_by_id('questionTypeSelect').click
        find('option', text: 'Boolean').click
        find('table', id: 'table-boolean')
      end

      it 'creates two answers, true and false' do
        expect(page).to have_content('True').and have_content('False')
      end

      it 'allows you to set an answer as correct' do
        find('span', id: 'best_in_place_answer_' + Answer.first.id.to_s + '_correct').click
        expect(page).to have_css('i.fa-check')
      end

      it 'does not allow you to remove an answer' do
        expect(page).to have_no_link('Remove')
      end
    end

    it 'allows you to add an answer' do
      visit(question_path(question))
      click_link('Add Answer')
      find('span', text: 'Click here to edit answer').click
      bip_text(Answer.first, :text, answer_text)
      expect(question.answers.first.text).to eq(answer_text)
    end

    it 'allows you to edit an existing answer' do
      answer
      visit(question_path(question))
      bip_text(Answer.first, :text, answer_text)
      expect(Answer.first.text).to eq(answer_text)
    end

    it 'allows you to delete an existing answer' do
      answer
      visit(question_path(question))
      expect { click_link('Remove') }.to change(Answer, :count).by(-1)
    end

    it 'allows you to assign a lesson to the question' do
      lesson
      visit(question_path(question))
      select lesson.title, from: 'Select Lesson'
      visit(question_path(question))
      expect(page).to have_content(lesson.title)
    end
  end
end
