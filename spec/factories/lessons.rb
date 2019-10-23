FactoryBot.define do
  factory :lesson do
    url { FFaker::Youtube.embed_url }
    type { 'video' }
    title { FFaker::BaconIpsum.sentence }
  end
end
