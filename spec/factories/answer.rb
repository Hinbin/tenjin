FactoryBot.define do
  factory :answer do
    sequence(:text) { FFaker::Lorem.sentence }
    question
    correct { 'false' }
  end
end
