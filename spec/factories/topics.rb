FactoryBot.define do
  factory :topic do
    name {'TestTopic'}
    association :subject, factory: :subject
  end
end
