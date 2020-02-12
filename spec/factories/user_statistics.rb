# frozen_string_literal: true

FactoryBot.define do
  factory :user_statistic do
    time_in_quizzes { rand(0..5000) }
    questions_answered { rand(0..5000) }
    last_seen_at { rand(DateTime.now - 1.month..DateTime.now) }
    week_beginning { rand(DateTime.now - 1.month..DateTime.now).beginning_of_week }
    user
  end
end
