FactoryBot.define do
  factory :classroom do
    name { '10x/Cs1' }
    description { 'Year 10 Computer Science' }
    code { '10x/Cs1' }
    sequence(:client_id)  { |n| "classroom#{n}" }
    association :subject, factory: :subject
    association :school, factory: :school
  end
end
