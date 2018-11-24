FactoryBot.define do
  factory :subject do
    sequence(:name)  { |n| "subject#{n}" }
  end
end
