# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User attempts a challenge", :default_creates, :js do
  let!(:challenge) do
    create(:challenge, topic: topic, challenge_type: "number_correct", number_required: 1)
  end
  let!(:question) { create(:question, topic: topic) }

  before do
    setup_subject_database
    sign_in student
    visit(dashboard_path)
  end

  it "marks the challenge complete after a correct answer" do
    expect(page).to have_no_css("#challenge-table .fa-check")
    find(".challenge-row").click
    find(".question-button").click
    find(".next-button").click
    expect(page).to have_css("#challenge-table .fa-check")
  end
end
