# frozen_string_literal: true

FactoryBot.define do
  factory :flagged_question do
    question
    user
  end
end
