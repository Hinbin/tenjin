FactoryBot.define do
  factory :classroom do
    name { '10x/Cs1' }
    description { 'Year 10 Computer Science' }
    code { '10x/Cs1' }
    client_id { 'classroom1' }
    association :subject, factory: :subject
    association :school, factory: :school
  end
end
