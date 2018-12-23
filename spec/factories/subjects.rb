FactoryBot.define do
  factory :subject do
    name { FFaker::HipsterIpsum.word }

    factory :computer_science do
      name { 'Computer Science' }
    end
  end
end
