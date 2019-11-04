# frozen_string_literal: true

class Subject < ApplicationRecord
  resourcify

  has_many :topics
  has_many :classrooms
  has_many :lessons

  validates :name, presence: true, uniqueness: true
end
