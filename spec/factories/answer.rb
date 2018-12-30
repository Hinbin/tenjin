FactoryBot.define do
  factory :answer do
    sequence(:text) { FFaker::HipsterIpsum.sentence }
    question
    correct { 'false' }
  end
end
