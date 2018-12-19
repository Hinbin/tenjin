FactoryBot.define do
  factory :subject do
    sequence(:name) { |n| "subject#{n}" }

    factory :computer_science do
      name { 'Computer Science' }
    end
  end
end
