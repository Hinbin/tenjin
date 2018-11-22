FactoryBot.define do
  factory :topic_score do
    score { 0 }
    association :user, factory: :student
    association :topic, factory: :topic
  end
end
