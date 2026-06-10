# frozen_string_literal: true

require "ffaker"

FactoryBot.define do
  factory :admin do
    email { FFaker::Internet.email }
    role { "super" }
    password { FFaker::Internet.password }

    factory :super_admin do
      role { "super" }
    end

    factory :school_group_admin do
      role { "school_group" }
    end
  end
end
