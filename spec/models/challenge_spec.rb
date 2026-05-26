# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge do
  let(:quiz_subject) { create(:subject) }
  let(:topic) { create(:topic, subject: quiz_subject) }
  let(:challenge_one) { described_class.create_challenge(topic.subject) }

  it "has a valid factory" do
    expect(build(:challenge)).to be_valid
  end

  describe "#create_challenge" do
    it "creates a challenge for the given subject" do
      expect(described_class.create_challenge(topic.subject).topic.subject).to eq(quiz_subject)
    end

    it "defaults to one week" do
      expect(described_class.create_challenge(topic.subject).end_date).to be_within(1.second).of(1.week.from_now)
    end

    context "with no challenge type specified" do
      let(:challenge_two) { described_class.create_challenge(topic.subject) }

      before { srand(1) }

      it "assigns a random challenge type" do
        expect(challenge_one.challenge_type).not_to eq(challenge_two.challenge_type)
      end
    end

    context "with a specified challenge type" do
      let(:challenge_full_marks) do
        create(:challenge, topic: topic, challenge_type: "number_correct",
          number_required: 10, end_date: 1.hour.from_now)
      end

      it "uses the specified challenge type" do
        expect(challenge_full_marks.challenge_type).to eq("number_correct")
      end
    end

    context "with a points multiplier" do
      before { srand(1) }

      it "scales the points" do
        expect(described_class.create_challenge(topic.subject, multiplier: 2).points).to eq(20)
      end
    end

    context "with no points multiplier" do
      before { srand(1) }

      it "awards base points" do
        expect(described_class.create_challenge(topic.subject).points).to eq(10)
      end
    end

    context "with a custom duration" do
      before { srand(1) }

      it "uses the given duration" do
        expect(described_class.create_challenge(topic.subject, duration: 3.days).end_date)
          .to be_within(1.second).of(3.days.from_now)
      end

      it "supports sub-day durations" do
        expect(described_class.create_challenge(topic.subject, duration: 36.hours).end_date)
          .to be_within(1.second).of(36.hours.from_now)
      end
    end

    context "with the daily flag" do
      before { srand(1) }

      it "is daily" do
        expect(described_class.create_challenge(topic.subject, daily: true)).to be_daily
      end
    end
  end

  describe "#stringify" do
    before { srand(1) }

    it "returns a formatted description" do
      expect(challenge_one.stringify).to eq("Obtain a streak of #{challenge_one.number_required} correct answers in \
#{topic.name} for #{topic.subject.name}")
    end
  end
end
