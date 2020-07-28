# frozen_string_literal:

require 'rails_helper'

RSpec.describe 'Author transfers question files', type: :system, js: true, default_creates: true do
  let(:author) { create(:question_author, subject: subject) }

  before do
    sign_in author
    topic
  end

  context 'when downloading questions' do
    it 'downloads questions' do
      visit topic_questions_questions_path(topic_id: topic.id)
      click_link('Import Questions')
      #expect(page).to have_content('Downloaded!')
    end
  end
end
