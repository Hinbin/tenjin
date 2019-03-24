require 'ffaker'

FactoryBot.define do
  factory :user do
    forename { FFaker::Name.first_name }
    surname { FFaker::Name.last_name }
    role { 'student' }
    provider { 'Wonde' }
    upi { SecureRandom.hex }
    association :school, factory: :school
    challenge_points { 0 }
    dashboard_style { 'red' }

    factory :student do
      role { 'student' }
    end

    factory :employee do
      role { 'employee' }
    end
  end
end
