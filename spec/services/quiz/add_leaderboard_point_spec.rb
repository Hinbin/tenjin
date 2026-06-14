# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quiz::AddLeaderboardPoint, :default_creates do
  let(:quiz) { create(:quiz, user: student, subject: quiz_subject, counts_for_leaderboard: true) }
  let(:question) { create(:question, topic: topic) }
  let(:topic_score) { TopicScore.find_by(user: student, topic: topic) }

  before do
    allow(Multiplier).to receive(:for_streak).and_return(2)
    allow(Challenge::UpdateChallengeProgress).to receive(:call)
    allow(Leaderboard::BroadcastLeaderboardPoint).to receive(:call)
  end

  context "when no prior topic score exists" do
    it "creates a topic score with the streak multiplier" do
      described_class.call(quiz: quiz, question: question)
      expect(topic_score.score).to eq(2)
    end

    it "broadcasts the leaderboard point" do
      described_class.call(quiz: quiz, question: question)
      expect(Leaderboard::BroadcastLeaderboardPoint).to have_received(:call).with(topic, student)
    end
  end

  context "when a prior topic score exists" do
    let!(:existing) { create(:topic_score, user: student, topic: topic, score: 5) }

    it "adds the multiplier to the existing score" do
      described_class.call(quiz: quiz, question: question)
      expect(topic_score.score).to eq(7)
    end

    it "accumulates across multiple calls" do
      3.times { described_class.call(quiz: quiz, question: question) }
      expect(topic_score.score).to eq(11)
    end
  end

  context "when the quiz does not count for the leaderboard" do
    let(:quiz) { create(:quiz, user: student, subject: quiz_subject, counts_for_leaderboard: false) }

    it "does not create a topic score" do
      expect { described_class.call(quiz: quiz, question: question) }.not_to change(TopicScore, :count)
    end

    it "does not broadcast" do
      described_class.call(quiz: quiz, question: question)
      expect(Leaderboard::BroadcastLeaderboardPoint).not_to have_received(:call)
    end
  end
end
