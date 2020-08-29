# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Author transfers question files', type: :system, js: true, default_creates: true do
  let(:author) { create(:question_author, subject: subject) }

  before do
    clear_downloads
    sign_in author
    topic
    question
    driven_by :selenium_chrome_headless_download
  end

  after do
    clear_downloads
  end

  it 'downloads questions' do
    skip if ENV['CI'] # Flakes out in CircleCI
    visit topic_questions_questions_path(topic_id: topic.id)
    click_link('Download Questions')
    wait_for_download
    expect(download).to match("#{topic.name}.json")
  end

  it 'uploads questions' do
    visit topic_questions_questions_path(topic_id: topic.id)
    click_link('Import Questions')
    attach_file('file', 'spec/fixtures/files/example_import.json', visible: false)
    click_button('Import')
    expect(page).to have_css('.question-text', count: 27)
  end

  it 'reports upload issues' do
    visit topic_questions_questions_path(topic_id: topic.id)
    click_link('Import Questions')
    attach_file('file', 'spec/fixtures/files/example_import_invalid.json', visible: false)
    click_button('Import')
    expect(page).to have_content('Question missing key')
  end

  it 'tells the user if they have not attached a file' do
    visit topic_questions_questions_path(topic_id: topic.id)
    click_link('Import Questions')
    click_button('Import')
    expect(page).to have_content('Please attach a file')
  end

  it 'ignores external ids'
  it 'allows you to delete multiple questions'
  it 'uploads the answers'
  it 'downloads json plaintext to question text'
end
