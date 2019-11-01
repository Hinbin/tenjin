# frozen_string_literal: true

require 'ffaker'

FactoryBot.define do
  factory :admin do
    email { FFaker::Internet.email }
    role { 'admin' }
    password { FFaker::Internet.password }

    factory :super_admin do
      role { 'super' }
    end
  end
end
