class School < ApplicationRecord
  has_many :users
  has_many :subject_maps
  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :token, presence: true

  enum sync_status: %i[never syncing successful failed needed]

  def self.from_wonde(client_school, token)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.token = token
    school.sync_status = 'never'
    school.save
    school
  end

  def self.from_wonde_sync_start(school)
    school.sync_status = 'syncing'
    school.save

    Enrollment.joins(:classroom).where('school_id = ?', school.id).destroy_all
    Classroom.where('school_id = ?', school.id).destroy_all
  end

  def self.from_wonde_sync_end(school)
    school.sync_status = 'successful'
    school.save
  end

  def self.school_from_client_id(client_id)
    School.where(client_id: client_id).first
  end

  def valid_subject_count
    subject_maps.where.not(subject_id: nil).count
  end

end
