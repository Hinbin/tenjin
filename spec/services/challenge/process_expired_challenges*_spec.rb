require 'rails_helper'

RSpec.describe Challenge::ProcessExpiredChallenges, :focus do
  include_context 'default_creates'

  context 'when finding expired challenges' do
    let(:current_challenge) { create(:challenge, end_date: DateTime.now + 1.hour) }
    let(:expired_challenge) { create(:challenge, end_date: DateTime.now - 1.hour) }

    it 'removes old challenges' do
      expired_challenge
      expect { Challenge::ProcessExpiredChallenges.new.call }.to change(Challenge, :count).by(-1)
    end

    it 'keeps_current_challenges' do
      current_challenge
      expect { Challenge::ProcessExpiredChallenges.new.call }.not_to change(Challenge, :count)
    end
  end
end
