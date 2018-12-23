FactoryBot.define do
  factory :school do
    client_id { SecureRandom.hex }
    name { FFaker::Education.school }
    token { SecureRandom.hex }
    permitted { true }
  end
end
