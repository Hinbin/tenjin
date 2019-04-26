require 'rails_helper'

RSpec.describe Challenge::ProcessExpiredChallenges do
  include_context 'default_creates'

  context 'when finding expired challenges' do
    let(:current) { create(:challenge, end_date: DateTime.now + 1.hour) }
    let(:expired) { create(:challenge, end_date: DateTime.now - 1.hour) }

    let(:completed) { create(:challenge_progress, challenge: expired, user: student, completed: true) }

    it 'deletes old challenges' do
      expired
      expect { described_class.new.call }.to change(Challenge, :count).by(-1)
    end

    it 'deletes old challenge progress' do
      completed
      expect { described_class.new.call }.to change(ChallengeProgress, :count).by(-1)
    end

    it 'keeps_current_challenges' do
      current
      expect { described_class.new.call }.not_to change(Challenge, :count)
    end
  end
end
