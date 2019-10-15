# frozen_string_literal: true

FactoryBot.define do
  factory :usage_statistic do
    user
    topic
    date { Time.now }
    quizzes_started { rand(0..20) }
    time_spent_in_seconds { rand(0..2000) }
    questions_answered { quizzes_started * rand(8..10) }
  end
end
