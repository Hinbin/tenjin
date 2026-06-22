# frozen_string_literal: true

FactoryBot.define do
  factory :question_import_hash, class: Hash do
    question_type { 'multiple' }
    question_text { { body: FFaker::Lorem.sentence } }
    answers do
      [
        { text: FFaker::Lorem.sentence, correct: true },
        { text: FFaker::Lorem.sentence, correct: false },
        { text: FFaker::Lorem.sentence, correct: false },
        { text: FFaker::Lorem.sentence, correct: false }
      ]
    end

    factory :question_import_hash_with_lesson do
      sequence(:lesson) { |n| "Lesson #{n}" }
    end

    factory :question_import_hash_two_option do
      answers do
        [
          { text: FFaker::Lorem.sentence, correct: true },
          { text: FFaker::Lorem.sentence, correct: false }
        ]
      end
    end

    initialize_with do
      attributes.deep_stringify_keys
    end
  end
end
