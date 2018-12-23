FactoryBot.define do
  factory :subject_map do
    sequence(:client_id)  { |n| "subject_map#{n}" }
    client_subject_name { FFaker::HipsterIpsum.word }
    association :subject, factory: :subject
    association :school, factory: :school
  end
end
