FactoryBot.define do
  factory :school do
    client_id { SecureRandom.hex }
    name { FFaker::Education.school }
    token { SecureRandom.hex }
    school_group

    permitted { true }
  end
end
