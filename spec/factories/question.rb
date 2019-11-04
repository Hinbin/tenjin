# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    sequence(:question_text) { |n| FFaker::Lorem.sentence + n.to_s }
    question_type { 'multiple' }
    association :topic, factory: :topic
    active { true }
    lesson { nil }

    factory :short_answer_question do
      question_type { 'short_answer' }
    end

    factory :question_with_lesson do
      lesson
    end

  end
end
