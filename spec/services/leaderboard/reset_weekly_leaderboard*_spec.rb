require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Leaderboard::ResetWeeklyLeaderboard do
  let(:topic_score) { create(:topic_score) }
  let(:existing_all_time_score) { create(:all_time_topic_score, user: topic_score.user, topic: topic_score.topic) }

  context 'when resetting topic scores' do
    it 'copies the current topic score into the all time topic score' do
      topic_score
      described_class.new.call
      expect(AllTimeTopicScore.first.score).to eq(topic_score.score)
    end

    it 'adds on to any existing all time topic score' do
      existing_all_time_score
      expect { described_class.new.call }.to change { AllTimeTopicScore.first.score }.by(topic_score.score)
    end

    it 'removes existing TopicScores' do
      topic_score
      expect { described_class.new.call }.to change(TopicScore, :count).by(-1)
    end
  end
end
