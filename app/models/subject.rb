# frozen_string_literal: true

class Subject < ApplicationRecord
  has_many :topics
  has_many :classrooms

  validates :name, presence: true, uniqueness: true

end
