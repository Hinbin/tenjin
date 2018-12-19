FactoryBot.define do
  factory :question do
    sequence(:text) { |n| "This is test question #{n}.  The answer is true" }
    question_type { 'multiple' }
    answers_count { 2 }
    image { nil }
    association :topic, factory: :topic
  end
end
