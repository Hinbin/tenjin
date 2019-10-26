# frozen_string_literal: true

class Lesson < ApplicationRecord
  validates :title, length: { minimum: 3 }, allow_blank: false
  validates :url,
            format: { with: %r{\Ahttp(?:s?):\/\/(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-\_]*)(&(amp;)?‌​[\w\?‌​=]*)?\z},
                      message: 'must be a YouTube video link e.g https://youtu.be/z1aIdcb43RE' }

  enum category: %i[video]
  has_many :questions
  belongs_to :topic

  has_one :subject, through: :topic
end
