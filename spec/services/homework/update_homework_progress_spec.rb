# frozen_string_literal: true

require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Homework::UpdateHomeworkProgress, :default_creates do
  context 'when updating a homework' do
    before do
      create(:enrollment, classroom: classroom, user: student)
      homework_full_marks
    end

    let(:quiz_full_marks) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 10,
                    answered_correct: 10, active: false, user: student)
    end

    let(:quiz_7_out_of_10) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 10,
                    answered_correct: 7, active: false, user: student)
    end
    let(:quiz_1_out_of_3) do
      create(:quiz, subject: subject, topic: topic, num_questions_asked: 3,
                    answered_correct: 1, active: false, user: student)
    end
    let(:homework_full_marks) { create(:homework, topic: topic, classroom: classroom, required: 100) }
    let(:homework_three_marks) { create(:homework, topic: topic, classroom: classroom, required: 30) }
    let(:homework_different_topic) { create(:hoemwork, topic: create(:topic), classroom: classroom, required: 100) }

    it 'flags homework as complete if the required number of questions have been answered correctly' do
      described_class.new(quiz_full_marks).call
      expect(HomeworkProgress.first.completed).to eq(true)
    end

    it 'sets progress to the highest percentage achieved' do
      described_class.new(quiz_7_out_of_10).call
      expect(HomeworkProgress.first.progress).to eq(70)
    end

    it 'ignores progress that is less than current progress' do
      described_class.new(quiz_full_marks).call
      described_class.new(quiz_7_out_of_10).call
      expect(HomeworkProgress.first.progress).to eq(100)
    end

    it 'handles fractions for progress' do
      homework_three_marks
      described_class.new(quiz_1_out_of_3).call
      expect(HomeworkProgress.where(homework: homework_three_marks).first.progress).to eq(33)
    end
  end
end
