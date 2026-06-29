# frozen_string_literal: true

# Precomputed standing of a student within a topic, relative to every other Tenjin student who has
# practised it. Refreshed weekly by Leaderboard::ComputeTopicPercentiles during the leaderboard reset,
# so the dashboard mastery bar can read it as an O(1) lookup instead of ranking the whole table live.
class TopicPercentile < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  validates :percentile, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :user, uniqueness: { scope: [:topic] }
end
