# frozen_string_literal: true

FactoryBot.define do
  factory :student_question_statistic do
    user factory: :student
    question
    number_asked { rand(1..50) }
    number_correct { rand(0..number_asked) }
    score_sum { number_correct.to_f }
    last_asked_at { Time.current }
  end
end
