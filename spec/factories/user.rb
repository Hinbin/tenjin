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
    time_of_last_quiz { rand((Time.now - 1.day)..(Time.now - 1.hour)) }
    username { forename[0].downcase + surname.downcase + upi[0..3] }
    password { FFaker::Internet.password }
    disabled { false }

    factory :student do
      role { 'student' }
    end

    factory :teacher do
      role { 'employee' }
      email { FFaker::Internet.email }
    end

    factory :school_admin do
      role { 'school_admin' }
      email { FFaker::Internet.email }
    end
  end
end
