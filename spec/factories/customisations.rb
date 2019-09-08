FactoryBot.define do
  factory :customisation do
    customisation_type { 0 }
    cost { rand(0..10) }
    sequence(:name) { |n| "#{FFaker::Lorem.word} #{n}" }
    value { FFaker::Lorem.word }
  end
end