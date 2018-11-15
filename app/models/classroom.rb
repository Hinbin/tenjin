class Classroom < ApplicationRecord
  belongs_to :subject
  belongs_to :school
  has_many :enrollments
  has_many :users, through: :enrollments

  def self.from_wonde(school_data, sync_data)
    school_client_id = school_data.id
    school = School.where(client_id: school_client_id).first
    mapped_subjects = SubjectMap.where.not(subject_id: nil).where(school_id: school)

    sync_data.each do |classroom|
      subject = mapped_subjects.where(client_subject_name: classroom.subject.data.name).first
      next unless subject.present?

      c = Classroom.where(client_id: classroom.client_id).first_or_initialize
      c.name = classroom.name
      c.description = classroom.description
      c.code = classroom.code
      c.school = school
      c.subject = subject.subject
      c.save
    end
  end
end
