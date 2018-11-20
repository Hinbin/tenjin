class Subject < ApplicationRecord
  has_many :topics
  has_many :classrooms
  has_many :subject_maps

  validates :name, presence: true
end
