# frozen_string_literal: true

FactoryBot.define do
  factory :user_statistic do
    questions_answered { rand(0..5000) }
    week_beginning { rand(Date.current - 1.month..Date.current).beginning_of_week }
    user
  end
end
