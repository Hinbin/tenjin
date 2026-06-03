# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Quiz, :default_creates, type: :model do
  let(:quiz) { create(:quiz, user: student, topic: topic) }
  let(:usage_statistic) { UsageStatistic.where(user: student).last }
  let(:old_statistic) { create(:usage_statistic, user: student, date: Time.now - 1.day) }

  context 'when creating a quiz' do
    it 'does not update usage statistics from a model callback' do
      expect { quiz }.not_to change(UsageStatistic, :count)
    end
  end

  context 'when recording quiz starts' do
    it 'increases the usage statistics quizzes created today by one' do
      quiz
      UsageStatistic::RecordQuizStart.call(quiz)
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it 'increases the usage statistics for the correct day' do
      old_statistic
      quiz
      UsageStatistic::RecordQuizStart.call(quiz)
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it 'increases the usage statistics for the correct record' do
      old_statistic
      quiz
      UsageStatistic::RecordQuizStart.call(quiz)
      expect(usage_statistic.id).not_to eq(old_statistic.id)
    end

    it 'increments an existing statistic atomically' do
      statistic = create(:usage_statistic, user: student, topic: topic, date: Date.current, quizzes_started: 2)

      expect { UsageStatistic::RecordQuizStart.call(quiz) }
        .to change { statistic.reload.quizzes_started }.from(2).to(3)
    end
  end
end
