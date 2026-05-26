# frozen_string_literal: true

FactoryBot.define do
  factory :asked_question do
    question
    association :quiz, strategy: :create

    correct { nil }
  end
end
