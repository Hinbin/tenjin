# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Author transfers question files", :default_creates, :js do
  let(:author) { create(:question_author, subject: quiz_subject) }
  let!(:topic) { create(:topic, subject: quiz_subject) }
  let!(:question) { create(:question, topic: topic) }

  before do
    driven_by :selenium_chrome_headless_download
    clear_downloads
    sign_in author
    visit topic_questions_path(topic_id: topic.id)
  end

  after do
    clear_downloads
  end

  it "downloads questions" do
    skip if ENV["CI"] # Flakes out in CircleCI
    click_link("Download Questions")
    wait_for_download
    expect(download).to match("#{topic.name}.json")
  end

  it "uploads questions" do
    click_link("Import Questions")
    attach_file("file", "spec/fixtures/files/example_import.json", visible: false)
    click_button("Import")
    expect(page).to have_css(".question-text", count: 27)
  end

  it "reports upload issues" do
    click_link("Import Questions")
    attach_file("file", "spec/fixtures/files/example_import_invalid.json", visible: false)
    click_button("Import")
    expect(page).to have_content("Question missing key")
  end

  it "tells the user if they have not attached a file" do
    click_link("Import Questions")
    click_button("Import")
    expect(page).to have_content("Please attach a file")
  end

  it "deletes multiple questions"
end
