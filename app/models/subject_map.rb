class SubjectMap < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :school

  def self.from_wonde(school_data, sync_data)
    school_client_id = school_data.id
    school_id = School.where(client_id: school_client_id).first.id

    sync_data.subjects.all.each do |client_subject|
      subject_map = where(client_id: client_subject.id).first_or_initialize
      subject_map.school_id = school_id
      subject_map.client_subject_name = client_subject.name

      # Check to see if this subject is in the default
      # subject map table
      default_subject = DefaultSubjectMap.where(name: subject_map.client_subject_name).first
      subject_map.subject = default_subject.subject if default_subject.present?
      subject_map.save
    end
  end
end
