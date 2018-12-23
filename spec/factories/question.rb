FactoryBot.define do
  factory :question do
    sequence(:text) { FFaker::HipsterIpsum.sentence }
    question_type { 'multiple' }
    answers_count { 2 }
    image { nil }
    association :topic, factory: :topic
  end
end
