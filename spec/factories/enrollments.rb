FactoryBot.define do
  factory :enrollment do
    association :classroom, factory: :classroom
    association :user, factory: :user
  end
end
