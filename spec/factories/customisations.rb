FactoryBot.define do
  factory :customisation do
    customisation_type { 0 }
    cost { rand(0..10) }
    name { FFaker::Lorem.word }
    value { FFaker::Lorem.word }
  end
end
