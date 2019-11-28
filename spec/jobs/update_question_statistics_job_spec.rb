# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateQuestionStatisticsJob, type: :job do
  let(:quiz) { create(:quiz, active: false) }
  let(:question) { create(:question) }
  let(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz) }
  let(:existing_statistic) { create(:question_statistic, question: question) }
  let(:question_statistic) { QuestionStatistic.where(question: question).first }

  context 'when question answered correctly' do
    it 'creates with number asked set to 1' do
      asked_question
      described_class.perform_now
      expect(question_statistic.number_asked).to eq(1)
    end

    it 'creates with number correct set to 1' do
      asked_question
      described_class.perform_now
      expect(question_statistic.number_correct).to eq(1)
    end

    it 'increments number correct' do
      existing_statistic
      asked_question
      described_class.perform_now
      expect { existing_statistic.reload }.to change(existing_statistic, :number_correct).by(1)
    end

    it 'increments number asked' do
      existing_statistic
      asked_question
      described_class.perform_now
      expect { existing_statistic.reload }.to change(existing_statistic, :number_asked).by(1)
    end
  end

  context 'when question answered incorrectly' do
    let(:asked_question) { create(:asked_question, question: question, correct: false, quiz: quiz) }

    it 'creates with number asked set to 1' do
      asked_question
      described_class.perform_now
      expect(question_statistic.number_asked).to eq(1)
    end

    it 'creates with number correct set to 0' do
      asked_question
      described_class.perform_now
      expect(question_statistic.number_correct).to eq(0)
    end

    it 'does not increment number correct' do
      existing_statistic
      asked_question
      described_class.perform_now
      expect { existing_statistic.reload }.to change(existing_statistic, :number_correct).by(0)
    end

    it 'increments number asked' do
      existing_statistic
      asked_question
      described_class.perform_now
      expect { existing_statistic.reload }.to change(existing_statistic, :number_asked).by(1)
    end
  end

  it 'removes old asked questions' do
    asked_question
    expect { described_class.perform_now }.to change(AskedQuestion, :count).by(-1)
  end

  context 'when the quiz is still active' do
    let(:quiz) { create(:quiz, active: true) }

    it 'does not process asked_questions for active quizzes' do
      asked_question
      expect { described_class.perform_now }.to change(AskedQuestion, :count).by(0)
    end
  end

  it 'checks for quizzes that have null values for active'
end
