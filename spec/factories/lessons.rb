# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    category { 'youtube' }
    title { FFaker::BaconIpsum.sentence }
    video_id { 'https://' + FFaker::Youtube.url }
    topic
  end
end
