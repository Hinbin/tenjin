# frozen_string_literal: true

class Topic < ApplicationRecord
  belongs_to :subject
  has_many :questions
  has_many :lessons
  belongs_to :default_lesson,
             optional: true,
             class_name: 'Lesson',
             foreign_key: 'default_lesson_id'

  validates :name, presence: true
end
