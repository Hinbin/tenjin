require 'rails_helper'

RSpec.describe Challenge::ProcessExpiredChallenges do
  include_context 'default_creates'

  context 'when finding expired challenges' do
    let(:current_challenge) { create(:challenge, end_date: DateTime.now - 1.hour) }
    let(:expired_challenge) { create(:challenge, end_date: DateTime.now + 1.hour) }

    let(:completed_challenge) { create(:challenge_progress, challenge: expired_challenge, user: student, completed: true) }

    it 'deletes old challenges' do
      expired_challenge
      expect { described_class.new.call }.to change(Challenge, :count).by(-1)
    end

    it 'deletes old challenge progress' do
      completed_challenge
      expect { described_class.new.call }.to change(ChallengeProgress, :count).by(-1)
    end

    it 'awards points for completed challenges' do
      completed_challenge
      described_class.new.call
      expect(User.first.challenge_points).to eq(expired_challenge.points)
    end

    it 'keeps_current_challenges' do
      current_challenge
      expect { described_class.new.call }.not_to change(Challenge, :count)
    end
  end
end
