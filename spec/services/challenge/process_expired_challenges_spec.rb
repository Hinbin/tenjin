# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge::ProcessExpiredChallenges, :default_creates do
  let!(:challenge) { create(:challenge, end_date: expiry) }
  let!(:progress) { create(:challenge_progress, challenge: challenge, user: student, completed: completed) }

  shared_examples "purges the challenge" do
    it "deletes the challenge and its progress" do
      expect { described_class.call }
        .to change(ChallengeProgress, :count).by(-1)
        .and change(Challenge, :count).by(-1)
    end
  end

  shared_examples "retains the challenge" do
    it "leaves the challenge and its progress intact" do
      expect { described_class.call }.not_to change(Challenge, :count)
      expect(ChallengeProgress.exists?(progress.id)).to be true
    end
  end

  context "when end_date is in the past" do
    let(:expiry) { 1.hour.ago }

    context "with a completed challenge" do
      let(:completed) { true }
      include_examples "purges the challenge"
    end

    context "with an incomplete challenge" do
      let(:completed) { false }
      include_examples "purges the challenge"
    end
  end

  context "when end_date is in the future" do
    let(:expiry) { 1.hour.from_now }

    context "with a completed challenge" do
      let(:completed) { true }
      include_examples "retains the challenge"
    end

    context "with an incomplete challenge" do
      let(:completed) { false }
      include_examples "retains the challenge"
    end
  end
end
