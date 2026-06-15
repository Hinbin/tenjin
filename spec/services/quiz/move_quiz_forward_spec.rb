# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz::MoveQuizForward, :default_creates do
  let(:questions) { create_list(:question, 5, topic: topic) }

  before { allow(Homework::UpdateHomeworkProgress).to receive(:call) }

  def build_quiz(num_questions_asked:)
    quiz = create(:quiz, num_questions_asked: num_questions_asked, subject: quiz_subject,
      topic: topic, user: student, active: true)
    questions.each { |question| create(:asked_question, quiz: quiz, question: question) }
    quiz
  end

  context "when on the final question" do
    let(:quiz) { build_quiz(num_questions_asked: 4) }

    it "increments num_questions_asked" do
      expect { described_class.call(quiz: quiz) }.to change { quiz.num_questions_asked }.by(1)
    end

    it "deactivates the quiz and notifies UpdateHomeworkProgress" do
      described_class.call(quiz: quiz)
      expect(quiz).not_to be_active
      expect(Homework::UpdateHomeworkProgress).to have_received(:call).with(quiz: quiz)
    end
  end

  context "when there are questions remaining" do
    let(:quiz) { build_quiz(num_questions_asked: 1) }

    it "leaves the quiz active and does not notify UpdateHomeworkProgress" do
      described_class.call(quiz: quiz)
      expect(quiz).to be_active
      expect(Homework::UpdateHomeworkProgress).not_to have_received(:call)
    end
  end
end
