# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    url { 'http://' + FFaker::Youtube.url }
    category { 'video' }
    title { FFaker::BaconIpsum.sentence }
    video_id { FFaker::Youtube.video_id }
  end
end
