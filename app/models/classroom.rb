class Classroom < ApplicationRecord
  belongs_to :subject
  belongs_to :school
  has_many :enrollments
end
