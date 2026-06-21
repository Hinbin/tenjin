# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Author builds a drag-and-drop question', :default_creates, :js, type: :system do
  let(:author) { create(:question_author, subject:) }
  let(:question) do
    create(:question, topic:, question_type: 'drag_drop', question_text: 'A {{1}}.',
                      config: { 'items' => [{ 'id' => 'i1', 'text' => 'one' }], 'answer' => { '1' => 'i1' } })
  end

  before do
    setup_subject_database
    sign_in author
    visit question_path(question)
  end

  it 'renders the builder editor with the existing item and an Add item button' do
    expect(page).to have_css('.tjs-builder__row')
    expect(page).to have_button('Add item')
  end

  it 'adds a new item row when Add item is clicked' do
    click_button 'Add item'
    expect(page).to have_css('.tjs-builder__row', count: 2)
  end
end
