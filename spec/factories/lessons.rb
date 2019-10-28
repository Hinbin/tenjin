# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    category { 'video' }
    title { FFaker::BaconIpsum.sentence }
    video_id { FFaker::Youtube.video_id }
    url { 'http://www.youtu.be/' + video_id }
  end
end
