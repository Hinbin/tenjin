FactoryBot.define do
  factory :customisation do
    customisation_type { 0 }
    cost { rand(0..10) }
    sequence(:name) { |n| "#{FFaker::Lorem.word} #{n}" }
    sequence(:value) { |n| "#{FFaker::Lorem.word} #{n}" }
  end
end