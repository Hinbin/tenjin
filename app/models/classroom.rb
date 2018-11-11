class Classroom < ApplicationRecord
  belongs_to :subject
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments

  def self.from_wonde(school_data, school_client_id)
  end
end
