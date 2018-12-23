FactoryBot.define do
  factory :classroom do
    name { FFaker::AddressUK.street_address }
    description { FFaker::AddressUK.street_name }
    code { FFaker::AddressUK.postcode }
    sequence(:client_id) { |n| "classroom#{n}" }
    disabled { false }
    subject
    school
  end
end
