require 'rails_helper'

RSpec.describe Challenge::AddNewChallenges do
  include_context 'default_creates'

  context 'when creating a new challenge' do
    it 'adds challenges for existing subjects' do
      create_list(:topic, 5)
      described_class.new.call
      expect(Challenge.count).to eq(5)
    end
  end
end
