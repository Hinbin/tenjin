# frozen_string_literal: true

FactoryBot.define do
  factory :question_statistic do
    number_asked { rand(1..100) }
    number_correct { number_asked - rand(0..number_asked) }
    question
  end
end
