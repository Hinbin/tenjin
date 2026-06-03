# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge::ProcessExpiredChallenges, :default_creates do
  context 'when finding expired challenges' do
    let(:current) { create(:challenge, end_date: Time.now + 1.hour) }
    let(:expired) { create(:challenge, end_date: Time.now - 1.hour) }
    let(:not_completed_expired) { create(:challenge, end_date: Time.now - 1.hour) }

    let(:completed) { create(:challenge_progress, challenge: expired, user: student, completed: true) }
    let(:not_completed) do
      create(:challenge_progress, challenge: not_completed_expired,
                                  user: student, completed: false)
    end

    it 'deletes old challenges' do
      expired
      expect { described_class.new.call }.to change(Challenge, :count).by(-1)
    end

    it 'deletes old challenge progress' do
      completed
      not_completed
      expect { described_class.new.call }.to change(ChallengeProgress, :count).by(-2)
    end

    it 'keeps_current_challenges' do
      current
      expect { described_class.new.call }.not_to change(Challenge, :count)
    end
  end
end
