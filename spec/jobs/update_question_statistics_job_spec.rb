# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateQuestionStatisticsJob, default_creates: true, type: :job do
  let(:quiz) { create(:quiz, active: false, user: student) }
  let(:question) { create(:question) }
  let(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz, user: student) }
  let(:existing_statistic) { create(:question_statistic, question: question) }
  let(:question_statistic) { QuestionStatistic.where(question: question).first }
  let(:current_user_statistic) do
    create(:user_statistic, user: student,
                            week_beginning: Date.current.beginning_of_week)
  end
  let(:old_user_statistic) do
    create(:user_statistic, user: student,
                            week_beginning: (Date.current - 1.month).beginning_of_week)
  end

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

  context 'when updating user statistics' do
    before do
      asked_question
    end

    it 'updates the user statistic for the correct week' do
      current_user_statistic
      described_class.perform_now
      expect { current_user_statistic.reload }.to change(current_user_statistic, :questions_answered).by(1)
    end

    it 'leaves older statistics alone' do
      old_user_statistic
      expect { current_user_statistic.reload }.to change(current_user_statistic, :questions_answered).by(0)
    end

    it 'creates new user statistics when old statistics present' do
      old_user_statistic
      expect { described_class.perform_now }.to change(UserStatistic, :count).by(1)
    end

    it 'creates a user statistic if needed' do
      expect { described_class.perform_now }.to change(UserStatistic, :count).by(1)
    end

    it 'assigns the correct user to the statistic' do
      described_class.perform_now
      expect(UserStatistic.first.user).to eq(asked_question.quiz.user)
    end
  end
end
