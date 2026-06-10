# frozen_string_literal: true

require "ffaker"

FactoryBot.define do
  factory :user do
    forename { FFaker::Name.first_name }
    surname { FFaker::Name.last_name }
    role { "student" }
    provider { "Wonde" }
    upi { SecureRandom.hex }
    association :school
    challenge_points { rand(0..30) * 10 }
    time_of_last_quiz { rand((1.day.ago)..(1.hour.ago)) }
    username { forename[0].downcase + surname.downcase + upi[0..3] }
    password { FFaker::Internet.password }
    disabled { false }
    oauth_email { FFaker::Internet.email }
    oauth_provider { "google_oauth2" }
    oauth_uid { rand(0..100_000_000_000) }

    trait :no_oauth do
      oauth_email { "" }
      oauth_provider { "" }
      oauth_uid { "" }
    end

    factory :student do
      role { "student" }
    end

    factory :teacher do
      role { "employee" }
    end

    factory :school_admin do
      role { "employee" }
      email { FFaker::Internet.email }
      after(:create) do |user, _evaluator|
        user.add_role :school_admin
      end
    end

    factory :question_author do
      transient do
        subject { subject }
      end

      role { "employee" }
      after(:create) do |user, evaluator|
        user.add_role :question_author, evaluator.subject
      end
    end
  end
end
