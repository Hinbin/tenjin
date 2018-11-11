FactoryBot.define do
  factory :default_subject_map do
    name { 'Computer Science' }
    association :subject, factory: :subject
  end
end
