# frozen_string_literal: true

FactoryBot.define do
  factory :all_time_topic_score do
    score { rand(1000) }
    user { nil }
    topic { nil }
  end
end
