# frozen_string_literal: true

FactoryBot.define do
  factory :challenge_progress do
    challenge
    user
    progress { 0 }
    completed { false }
  end
end
