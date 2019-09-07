RSpec.describe 'Author edits a question', type: :feature, js: true do
  include_context 'default_creates'

  let(:author) { create(:author) }
  let(:question) { create(:question, topic: topic) }
  let(:new_topic_name) { FFaker::Lorem.word }

  before do
    setup_subject_database
    sign_in author
  end

  context 'when adding or removing questions' do
    before do
      question
      visit(questions_path)
      click_link(question.topic.name)
    end

    it 'allows you to create a question' do
      click_link('Add Question')
      expect(page).to have_css('#questionEditor')
    end

    it 'allows you to delete a question' do
      visit(question_path(question))
      click_link('Delete Question')
      expect(page).to have_no_css('.question-row')
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

    it 'allows you to delete a topic' do
      click_link('Add Topic')
      click_link('Delete Topic')
      expect(page).to have_no_css('.topic-row')
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
      expect { click_link('Delete Question') }.to change(Question, :count).by(-1)
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
  end
end
