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

  context 'when authoring a drag-and-drop question' do
    let(:topic) { create(:topic, subject: subject) }
    let(:question) do
      create(:question, topic: topic, question_type: 'drag_drop',
                        config: { 'text' => 'A {{1}}.', 'items' => [{ 'id' => 'i1', 'text' => 'one' }],
                                  'answer' => { '1' => 'i1' } })
    end

    before { sign_in author }

    it 'shows the drag-and-drop authoring instructions and builder' do
      get question_path(question)
      expect(response.body).to include('How to build a drag-and-drop question')
        .and include('data-question-builder-type-value="drag_drop"')
    end
  end
end
