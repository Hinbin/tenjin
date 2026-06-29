# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'using question editing', type: :request do
  let(:subject) { create(:subject) }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:author) { create(:question_author, subject: subject) }

  context 'when I am a student' do
    it 'redirects me to the dashboard' do
      sign_in student
      get topics_path
      expect(response).to redirect_to(root_path)
    end
  end

  context 'when viewing questions for a topic' do
    before do
      sign_in author
    end

    it 'displays the questions index page' do
      get topics_path
      expect(response).to have_http_status(:success)
    end
  end

  context 'when editing a question from the review queue' do
    let(:topic) { create(:topic, subject: subject) }
    let(:pending_question) do
      create(:question, topic: topic, review_status: :pending, active: false)
    end

    before { sign_in author }

    it 'links each queued question to its edit screen with queue-flavoured buttons' do
      get question_path(pending_question)

      expect(response.body).to include('Accept and save')
        .and include('Delete from queue')
    end

    it 'accepts and saves edits, approving the question and returning to the queue' do
      patch question_path(pending_question),
            params: { question: { question_text: 'Edited while reviewing' } }

      expect(pending_question.reload).to have_attributes(review_status: 'approved', active: true)
      expect(pending_question.question_text.to_plain_text).to eq('Edited while reviewing')
      expect(response).to redirect_to(question_reviews_path)
    end

    it 'removes a queued question from the queue by rejecting it' do
      delete question_path(pending_question)

      expect(pending_question.reload).to have_attributes(review_status: 'rejected', active: false)
      expect(response).to redirect_to(question_reviews_path)
    end
  end

  context 'when deleting a live question' do
    let(:topic) { create(:topic, subject: subject) }
    let(:question) { create(:question, topic: topic) }

    before { sign_in author }

    it 'deactivates it and returns to the topic' do
      delete question_path(question)

      expect(question.reload.active).to be(false)
      expect(response).to redirect_to(topic_path(topic))
    end
  end

  context 'when authoring a drag-and-drop question' do
    let(:topic) { create(:topic, subject: subject) }
    let(:question) do
      create(:question, topic: topic, question_type: 'drag_drop', question_text: 'A {{1}}.',
                        config: { 'items' => [{ 'id' => 'i1', 'text' => 'one' }], 'answer' => { '1' => 'i1' } })
    end

    before { sign_in author }

    it 'shows the drag-and-drop authoring instructions and builder' do
      get question_path(question)
      expect(response.body).to include('How to build a drag-and-drop question')
        .and include('data-question-builder-type-value="drag_drop"')
    end
  end
end
