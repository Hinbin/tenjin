class Subject < ApplicationRecord
  has_many :topics
  has_many :classrooms
  has_many :subject_maps

  validates :name, presence: true, uniqueness: true

  def self.for_school(school)
    Subject.joins(:subject_maps).where(school_id: school.id).distinct
  end
end
