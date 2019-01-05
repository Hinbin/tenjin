FactoryBot.define do
  factory :topic do
    name {FFaker::Lorem.word}
    association :subject, factory: :subject
  end
end
