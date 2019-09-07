class Classroom < ApplicationRecord
  belongs_to :subject
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments
  has_many :homeworks

  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true

  def self.from_wonde(school, sync_data)
    mapped_subjects = SubjectMap.subject_maps_for_school(school)
    sync_data.each do |classroom|
      subject = mapped_subjects.where(client_subject_name: classroom.subject.data.name).first
      create_classroom(classroom, school, subject) if subject.present?
    end
  end

  def self.create_classroom(classroom, school, subject)
    c = Classroom.where(client_id: classroom.id).first_or_initialize
    c.client_id = classroom.id
    c.name = classroom.name
    c.description = classroom.description
    c.code = classroom.code
    c.school_id = school.id
    c.subject_id = subject.subject.id
    c.disabled = false
    c.save
  end

  def self.classroom_from_client_id(client_id)
    Classroom.where(client_id: client_id).first
  end
end
