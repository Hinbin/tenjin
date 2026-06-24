# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Leaderboard::BroadcastLeaderboardPoint, :default_creates do
  describe '#call' do
    before do
      student_topic_score
    end

    it 'broadcasts to the student own school channel (not the school group)' do
      expect do
        described_class.new(student_topic_score, student).call
      end.to have_broadcasted_to("leaderboard:#{subject.name}:#{school.name}")
        .with(hash_including(topic: topic.id))
    end
  end
end
