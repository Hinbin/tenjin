FactoryBot.define do
  factory :topic do
    name {FFaker::HipsterIpsum.word}
    association :subject, factory: :subject
  end
end
