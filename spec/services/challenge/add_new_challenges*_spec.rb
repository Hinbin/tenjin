require 'rails_helper'

RSpec.describe Challenge::AddNewChallenges do
  include_context 'default_creates'

  context 'when creating a new challenge' do
    it 'adds challenges for existing subjects' do
      create_list(:topic, 5)
      described_class.new.call
      expect(Challenge.count).to eq(5)
    end

    it 'sets the duration correctly' do
      create(:topic)
      described_class.new(duration: 3.days).call
      expect(Challenge.first.end_date).to be_within(1.second).of(Time.now + 3.days)
    end

    it 'sets the multiplier correctly' do
      srand(1)
      create(:topic)
      described_class.new(multiplier: 4).call
      expect(Challenge.first.points).to eq(40)
    end
  end
end
