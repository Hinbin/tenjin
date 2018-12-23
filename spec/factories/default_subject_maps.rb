FactoryBot.define do
  factory :default_subject_map do
    name { FFaker::HipsterIpsum.word }
    association :subject, factory: :subject
  end
end
