# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Challenge::AddNewChallenges, :default_creates do
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

    it 'sets a daily challenge correctly' do
      srand(1)
      create(:topic)
      described_class.new(daily: true).call
      expect(Challenge.first.daily).to eq(true)
    end

    it 'defaults to a non daily challenge' do
      srand(1)
      create(:topic)
      described_class.new.call
      expect(Challenge.first.daily).to eq(false)
    end
  end
end
