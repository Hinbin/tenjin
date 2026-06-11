# frozen_string_literal: true

class Lesson < ApplicationRecord
  LINK_REGEX = [
    [:no_content, /\A[[:blank:]]*\z/],
    [:vimeo, %r{(?:(?:https?:)?//)?(?:www.)?(?:player.)?vimeo.com/(?:[a-z]*/)*(\d+)(?:\S*)}],
    [:youtube,
      %r{(?:(?:https?:)?//)?(?:(?:www|m)\.)?(?:youtube(?:-nocookie)?.com|youtu.be)(?:/(?:[\w\-.@]+\?v=|embed/|v/)?)([\w-]+)(?:\S*)}]
  ].freeze
  CATEGORY_VIDEOS = {
    youtube: "https://www.youtube.com/embed/%s",
    vimeo: "https://player.vimeo.com/video/%s"
  }.freeze
  CATEGORY_THUMBNAILS = {
    youtube: "https://img.youtube.com/vi/%s/hqdefault.jpg"
  }.freeze

  enum :category, {youtube: 0, vimeo: 1, no_content: 2}

  belongs_to :topic
  has_many :homeworks
  has_many :questions
  has_many :quizzes

  has_one :subject, through: :topic

  attribute :video_link, :string

  before_destroy { |record| Question.where(lesson: record).update_all(lesson_id: nil) }

  validates :title, length: {minimum: 3}
  validate :check_video_link

  def video_link=(value)
    self.category, self.video_id = extract_id(value)
    super
  end

  def video_link
    super || video_url
  end

  def video_url
    format = CATEGORY_VIDEOS[category&.to_sym]
    format && (format % video_id)
  end

  def thumbnail_url
    format = CATEGORY_THUMBNAILS[category&.to_sym]
    format && (format % video_id)
  end

  private

  def extract_id(url)
    kind = LINK_REGEX.lazy.filter_map do |c, r|
      (vid = r.match(url)) && [c, vid&.captures&.first]
    end

    kind.first || [:no_content, nil]
  end

  def check_video_link
    return unless video_link.present? && video_id.nil?

    errors.add :video_link, "Must be a YouTube or Vimeo link e.g https://youtu.be/z1aIdcb43RE"
  end
end
