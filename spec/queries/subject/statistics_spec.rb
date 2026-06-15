# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subject::Statistics, :default_creates do
  subject(:stats) { described_class.new(quiz_subject) }

  let(:question) { create(:question, topic: topic) }

  context "with asked questions this week" do
    before { create_list(:asked_question, 5, question: question) }

    it "returns the asked question count" do
      expect(stats).to have_attributes(
        asked_questions: 5,
        asked_questions_this_week: 5
      )
    end
  end

  context "with previous week statistics only" do
    before { create(:question_statistic, question: question, number_asked: 7) }

    it "returns the historical count without inflating the this-week count" do
      expect(stats).to have_attributes(
        asked_questions: 7,
        asked_questions_this_week: 0
      )
    end
  end

  context "with both this week and previous statistics" do
    before do
      create_list(:asked_question, 5, question: question)
      create(:question_statistic, question: question, number_asked: 7)
    end

    it "sums historical and this-week into the total but keeps this-week separate" do
      expect(stats).to have_attributes(
        asked_questions: 12,
        asked_questions_this_week: 5
      )
    end
  end

  it "memoizes asked_questions" do
    stats.asked_questions
    expect(AskedQuestion).not_to receive(:joins)
    stats.asked_questions
  end

  it "memoizes asked_questions_this_week" do
    stats.asked_questions_this_week
    expect(AskedQuestion).not_to receive(:joins)
    stats.asked_questions_this_week
  end
end
