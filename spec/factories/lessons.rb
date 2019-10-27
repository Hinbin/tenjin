# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    url { 'http://' + FFaker::Youtube.url }
    category { 'video' }
    video_id { FFaker::Youtube.video_id }
    topic
  end
end
