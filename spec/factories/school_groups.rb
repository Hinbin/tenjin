# frozen_string_literal: true

FactoryBot.define do
  factory :school_group do
    name { FFaker::Education.school_name }
  end
end
