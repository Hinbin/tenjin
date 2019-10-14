# frozen_string_literal: true

FactoryBot.define do
  factory :answer do
    sequence(:text) { |n| FFaker::Lorem.sentence + n.to_s }
    question
    correct { 'false' }
  end
end
