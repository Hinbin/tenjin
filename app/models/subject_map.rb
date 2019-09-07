class SubjectMap < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :school

  validates :client_id, presence: true, uniqueness: true
  validates :client_subject_name, presence: true

  def self.from_wonde(school, client_subject)
    create_subject_map(client_subject, school)
  end

  def self.create_subject_map(client_subject, school)
    subject_map = where(client_id: client_subject.id).first_or_initialize
    subject_map.school_id = school.id
    subject_map.client_subject_name = client_subject.name

    # Check to see if this subject is in the default
    # subject map table
    default_subject = DefaultSubjectMap.where(name: subject_map.client_subject_name).first
    subject_map.subject_id = default_subject.subject.id if default_subject.present?
    subject_map.save
  end

  def self.subject_maps_for_school(school)
    SubjectMap.where.not(subject_id: nil).where(school_id: school)
  end
end
