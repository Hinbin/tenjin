# frozen_string_literal: true

FactoryBot.define do
  factory :active_customisation do
    customisation
    user
  end
end
