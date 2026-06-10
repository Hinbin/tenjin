# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Author transfers question files", :default_creates, :js do
  let(:author) { create(:question_author, subject: quiz_subject) }
  let!(:question) { create(:question, topic: topic) }

  before do
    sign_in author
    visit topic_questions_path(topic_id: topic.id)
  end

  describe "uploading questions" do
    it "imports questions from a valid JSON file" do
      click_link("Import Questions")
      attach_file("file", Rails.root.join("spec/fixtures/files/example_import.json").to_s, visible: false)
      click_button("Import")
      within "#questionTable" do
        expect(page).to have_css("[id^='question-']", count: 27)
      end
    end

    it "reports issues with an invalid JSON file" do
      click_link("Import Questions")
      attach_file("file", Rails.root.join("spec/fixtures/files/example_import_invalid.json").to_s, visible: false)
      click_button("Import")
      expect(page).to have_content("Question missing key")
    end
  end
end
