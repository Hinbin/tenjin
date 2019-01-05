FactoryBot.define do
  factory :subject do
    name { FFaker::Lorem.word }

    factory :computer_science do
      name { 'Computer Science' }
    end
  end
end
