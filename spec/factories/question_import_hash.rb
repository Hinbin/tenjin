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
      sequence(:lesson) { |n| FFaker::Lorem.word + n.to_s }
    end

    factory :question_import_hash_boolean do
      answers do
        [
          { text: 'True', correct: true },
          { text: 'False', correct: false }
        ]
      end
    end

    initialize_with do
      attributes.deep_stringify_keys
    end
  end
end
