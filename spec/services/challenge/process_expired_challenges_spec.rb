# frozen_string_literal: true

require "rails_helper"

RSpec.describe Challenge::ProcessExpiredChallenges, :default_creates do
  let!(:challenge) { create(:challenge, end_date: expiry) }
  let!(:progress) { create(:challenge_progress, challenge: challenge, user: student, completed: completed) }

  subject { described_class.call }

  context "when end_date is in the past" do
    let(:expiry) { 1.hour.ago }

    context "with a completed challenge" do
      let(:completed) { true }

      it("deletes the progress") { expect { subject }.to change(ChallengeProgress, :count).by(-1) }
      it("deletes the challenge") { expect { subject }.to change(Challenge, :count).by(-1) }
    end

    context "with an incomplete challenge" do
      let(:completed) { false }

      it("deletes the progress") { expect { subject }.to change(ChallengeProgress, :count).by(-1) }
      it("deletes the challenge") { expect { subject }.to change(Challenge, :count).by(-1) }
    end
  end

  context "when end_date is in the future" do
    let(:expiry) { 1.hour.from_now }

    context "with a completed challenge" do
      let(:completed) { true }

      it("does not delete the progress") { expect { subject }.not_to change(ChallengeProgress, :count) }
      it("does not delete the challenge") { expect { subject }.not_to change(Challenge, :count) }
    end

    context "with an incomplete challenge" do
      let(:completed) { false }

      it("does not delete the progress") { expect { subject }.not_to change(ChallengeProgress, :count) }
      it("does not delete the challenge") { expect { subject }.not_to change(Challenge, :count) }
    end
  end
end
