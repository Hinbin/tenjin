require 'rails_helper'

RSpec.describe Quiz, type: :model, default_creates: true do
  let(:quiz) { create(:quiz, user: student, topic: topic) }
  let(:usage_statistic) { UsageStatistic.where(user: student).last }
  let(:old_statistic) { create(:usage_statistic, user: student, date: Time.now - 1.day) }

  context 'when creating a quiz' do
    it 'increases the usage statistics quizzes created today by one' do
      quiz
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it 'increases the usage statistics for the correct day' do
      old_statistic
      quiz
      expect(usage_statistic.quizzes_started).to eq(1)
    end

    it 'increases the usage statistics for the correct record' do
      old_statistic
      quiz
      expect(usage_statistic.id).not_to eq(old_statistic.id)
    end
  end
end
