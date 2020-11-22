# frozen_string_literal: true

FactoryBot.define do
  factory :customisation do
    customisation_type { 0 }
    cost { rand(0..10) }
    sequence(:name) { |n| "#{FFaker::Lorem.word} #{n}" }
    sequence(:value) { |n| "#{FFaker::Lorem.word}#{n}" }
    purchasable { true }
  end
end
