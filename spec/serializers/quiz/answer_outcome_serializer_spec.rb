# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz::AnswerOutcomeSerializer do
  it "produces a hash with the wire-format keys" do
    question = create(:question)
    outcome = Quiz::CheckAnswerOutcome.new(question: question, streak: 3, answered_correct: 7, multiplier: 2)
    json = described_class.new(outcome).as_json
    expect(json).to include(:answer, streak: 3, answeredCorrect: 7, multiplier: 2)
  end
end
