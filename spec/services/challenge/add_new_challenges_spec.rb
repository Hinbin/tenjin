# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge::AddNewChallenges, :default_creates do
  context "with multiple topics" do
    before { create_list(:topic, 5) }

    it "creates a challenge for each topic" do
      described_class.call
      expect(Challenge.count).to eq(5)
    end
  end

  context "with a single topic" do
    before do
      srand(1)
      create(:topic)
    end

    it "sets end_date from duration param" do
      described_class.call(duration: 3.days)
      expect(Challenge.first.end_date).to be_within(1.second).of(3.days.from_now)
    end

    it "uses multiplier to scale points" do
      described_class.call(multiplier: 4)
      expect(Challenge.first.points).to eq(40)
    end

    context "with daily flag" do
      it "marks the challenge as daily" do
        described_class.call(daily: true)
        expect(Challenge.first.daily).to be true
      end
    end

    context "without daily flag" do
      it "defaults to a non-daily challenge" do
        described_class.call
        expect(Challenge.first.daily).to be false
      end
    end
  end
end
