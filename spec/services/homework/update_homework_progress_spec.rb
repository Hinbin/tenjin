# frozen_string_literal: true

require "rails_helper"

RSpec.describe Homework::UpdateHomeworkProgress, :default_creates do
  let!(:enrollment) { create(:enrollment, classroom: classroom, user: student) }
  let!(:homework) { create(:homework, topic: topic, classroom: classroom, required: mark_required) }
  let(:progress) { HomeworkProgress.find_by(homework: homework) }

  context "when the required mark is 100" do
    let(:mark_required) { 100 }

    let(:quiz_full_marks) do
      create(:quiz, subject: quiz_subject, topic: topic, num_questions_asked: 10,
        answered_correct: 10, active: false, user: student)
    end

    let(:quiz_7_out_of_10) do
      create(:quiz, subject: quiz_subject, topic: topic, num_questions_asked: 10,
        answered_correct: 7, active: false, user: student)
    end

    it "marks the homework as complete" do
      described_class.call(quiz_full_marks)
      expect(progress.completed).to be true
    end

    it "does not mark the homework as complete below the required mark" do
      described_class.call(quiz_7_out_of_10)
      expect(progress.completed).to be false
    end

    it "calculates progress as a percentage of correct answers" do
      described_class.call(quiz_7_out_of_10)
      expect(progress.progress).to eq(70)
    end

    it "ignores progress that is less than current progress" do
      described_class.call(quiz_full_marks)
      described_class.call(quiz_7_out_of_10)
      expect(progress.progress).to eq(100)
    end
  end

  context "when the required mark is 30" do
    let(:mark_required) { 30 }

    let(:quiz_1_out_of_3) do
      create(:quiz, subject: quiz_subject, topic: topic, num_questions_asked: 3,
        answered_correct: 1, active: false, user: student)
    end

    it "truncates fractional percentages to the nearest integer" do
      described_class.call(quiz_1_out_of_3)
      expect(progress.progress).to eq(33)
    end
  end
end
