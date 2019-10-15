# frozen_string_literal: true

FactoryBot.define do
  factory :classroom_winner do
    user
    classroom
    score { rand(0..100) }
  end
end
