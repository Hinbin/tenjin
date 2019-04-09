FactoryBot.define do
  factory :question do
    sequence(:question_text) { FFaker::Lorem.sentence }
    question_type { 'multiple' }
    answers_count { 2 }
    image { nil }
    association :topic, factory: :topic

    factory :short_answer_question do
      question_type { 'short_answer' }
    end
  end
end
