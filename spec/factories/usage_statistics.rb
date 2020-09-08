# frozen_string_literal: true

FactoryBot.define do
  factory :usage_statistic do
    user
    topic
    lesson { nil }
    date { Time.now }
    quizzes_started { rand(0..20) }
    questions_answered { quizzes_started * rand(8..10) }
  end
end
