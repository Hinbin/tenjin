require 'ffaker'

FactoryBot.define do
  factory :admin do
    email { FFaker::Internet.email }
    role { 'admin' }
    password { FFaker::Internet.password }

    factory :author do
      role { 'author' }
    end
  end
end
