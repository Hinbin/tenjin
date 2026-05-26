# frozen_string_literal: true

FactoryBot.define do
  factory :leaderboard_award do
    school
    user
    subject

    trait :without_user do
      user { nil }
    end
  end
end
