# frozen_string_literal: true

FactoryBot.define do
  factory :user_statistic do
    questions_answered { rand(0..5000) }
    week_beginning { rand(Date.today - 1.month..Date.today).beginning_of_week }
    user
  end
end
