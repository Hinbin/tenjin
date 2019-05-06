FactoryBot.define do
  factory :customisation_unlock do
    customisation
    user
    active { false }
  end
end
