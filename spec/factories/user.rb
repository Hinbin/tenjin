require 'ffaker'

FactoryBot.define do
  factory :user do
    forename { FFaker::Name.first_name }
    surname { FFaker::Name.last_name }
    role { 'student' }
    provider { 'Wonde' }
    upi { SecureRandom.hex}
    association :school, factory: :school

    factory :student do
      role { 'student' }
    end

    factory :employee do
      role { 'employee' }
    end
  end
end
