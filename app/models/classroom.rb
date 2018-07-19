class Classroom < ApplicationRecord
  belongs_to :subject
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments
end
