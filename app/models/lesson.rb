# frozen_string_literal: true

class Lesson < ApplicationRecord
  validates_length_of :title, minimum: 3
  validate :check_video_id

  enum category: %i[youtube vimeo]
  has_many :questions
  has_many :default_lessons
  belongs_to :topic

  has_one :subject, through: :topic

  before_save :save_video_id

  def generate_video_src
    return "https://www.youtube.com/embed/#{video_id}" if youtube?
    return "https://player.vimeo.com/video/#{video_id}" if vimeo?
  end

  def generate_thumbnail_src
    return "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg" if youtube?
  end

  private

  def check_video_id
    result = find_video_id
    errors[:video_id] << 'Must be a YouTube or Vimeo link e.g https://youtu.be/z1aIdcb43RE' if result.blank?
  end

  def save_video_id
    result = find_video_id
    self.category = result[:category]
    self.video_id = result[:video_id]
  end

  def find_video_id
    return nil if video_id.blank?

    regexes = [{ category: 'youtube',
                 regex: %r{http(?:s?)://(?:www\.)?youtu(?:be\.com/watch\?v=|\.be/)([\w\-\_]*)(&(amp;)?‌​[\w\?‌​=]*)?} },
               { category: 'vimeo',
                 regex: %r{(?:http|https)?:\/\/(?:www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/(?:[^\/]*)\/videos\/|)(\d+)(?:|\/\?)} }]

    regexes.each do |r|
      return { category: r[:category], video_id: video_id.match(r[:regex]).captures[0] } if video_id.match(r[:regex])
    end

    nil
  end
end
