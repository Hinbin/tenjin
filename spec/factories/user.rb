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
    time_of_last_quiz { rand((Time.now - 1.day)..(Time.now - 1.hour)) }

    factory :student do
      role { 'student' }
    end

    factory :teacher do
      role { 'employee' }
    end
  end
end
