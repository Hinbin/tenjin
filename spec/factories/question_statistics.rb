# frozen_string_literal: true

FactoryBot.define do
  factory :question_statistic do
    number_asked { rand(1..100) }
    number_correct { number_asked - rand(0..number_asked) }
    score_sum { number_correct.to_f }
    question
  end
end
