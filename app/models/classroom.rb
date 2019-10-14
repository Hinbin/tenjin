class Classroom < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments
  has_many :homeworks

  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_wonde(school, classroom)
    create_classroom(classroom, school)
  end

  def self.create_classroom(classroom, school)
    c = Classroom.where(client_id: classroom.id).first_or_initialize
    c.client_id = classroom.id
    c.name = classroom.name
    c.description = classroom.description
    c.code = classroom.code
    c.school_id = school.id
    c.disabled = false
    c.save
    c
  end
end
