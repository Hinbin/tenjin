# frozen_string_literal: true

FactoryBot.define do
  factory :customisation_unlock do
    customisation
    user
  end
end
