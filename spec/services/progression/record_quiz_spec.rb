# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Progression::RecordQuiz do
  subject(:record) { described_class.call(user:, quiz:) }

  let(:user) { create(:student, xp: 0, level: 1, streak_days: 0, last_streak_day: nil, challenge_points: 50) }
  let(:quiz) { create(:quiz, user:, answered_correct: 4, progression_recorded_at: nil) }

  describe 'XP and level' do
    it 'adds the quiz points to the user xp' do
      expect { record }.to change { user.reload.xp }.from(0).to(40)
    end

    it 'recomputes the level from the new xp' do
      quiz.update!(answered_correct: 10) # 100 xp -> level 2
      expect { record }.to change { user.reload.level }.from(1).to(2)
    end

    it 'leaves the spendable wallet (challenge_points) untouched' do
      expect { record }.not_to(change { user.reload.challenge_points })
    end
  end

  describe 'streak continuity' do
    it 'starts a fresh streak at 1 when there is no prior day' do
      record
      expect(user.reload.streak_days).to eq(1)
      expect(user.last_streak_day).to eq(Date.current)
    end

    it 'increments the streak when the last day was yesterday' do
      user.update!(streak_days: 3, last_streak_day: Date.current - 1)
      expect { record }.to change { user.reload.streak_days }.from(3).to(4)
    end

    it 'leaves the streak unchanged when already played today' do
      user.update!(streak_days: 5, last_streak_day: Date.current)
      expect { record }.not_to(change { user.reload.streak_days })
    end

    it 'resets the streak to 1 after a gap' do
      user.update!(streak_days: 9, last_streak_day: Date.current - 3)
      expect { record }.to change { user.reload.streak_days }.from(9).to(1)
    end
  end

  describe 'idempotency' do
    it 'stamps the quiz as recorded' do
      expect { record }.to change { quiz.reload.progression_recorded_at }.from(nil)
    end

    it 'does not apply xp twice on a replay' do
      record
      expect { described_class.call(user:, quiz:) }.not_to(change { user.reload.xp })
    end

    it 'does not advance the streak on a replay' do
      user.update!(streak_days: 2, last_streak_day: Date.current - 1)
      record
      expect { described_class.call(user:, quiz:) }.not_to(change { user.reload.streak_days })
    end

    it 'reports whether it recorded' do
      expect(record.recorded).to be(true)
      expect(described_class.call(user:, quiz:).recorded).to be(false)
    end
  end
end
