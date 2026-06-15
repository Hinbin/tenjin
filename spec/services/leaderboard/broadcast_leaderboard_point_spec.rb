# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::BroadcastLeaderboardPoint, :default_creates do
  before { allow(LeaderboardChannel).to receive(:broadcast_to) }

  context "when the school has a school group" do
    let!(:topic_score) { create(:topic_score, user: student, topic: topic, score: 10) }

    it "broadcasts to a channel scoped to the school group with scores" do
      described_class.call(topic, student)
      expected_channel = "#{topic.subject.name}:#{student.school.school_group.name}"
      expect(LeaderboardChannel).to have_received(:broadcast_to).with(
        expected_channel,
        hash_including(id: student.id, topic_score: anything, subject_score: anything)
      )
    end
  end

  context "when the school has no school group" do
    let(:school_without_group) { create(:school, school_group: nil) }
    let(:local_student) { create(:student, school: school_without_group) }
    let!(:topic_score) { create(:topic_score, user: local_student, topic: topic, score: 5) }

    it "broadcasts to a channel scoped to the school" do
      described_class.call(topic, local_student)
      expected_channel = "#{topic.subject.name}:#{school_without_group.name}"
      expect(LeaderboardChannel).to have_received(:broadcast_to).with(expected_channel, anything)
    end
  end
end
