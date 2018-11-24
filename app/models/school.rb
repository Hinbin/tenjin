class School < ApplicationRecord
  has_many :users
  has_many :subject_maps
  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :token, presence: true

  def self.from_wonde(client_school, token)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.token = token
    school.sync_in_progress = false
    school.save
    school
  end

  def self.school_from_client_id(client_id)
    School.where(client_id: client_id).first
  end

  def valid_subject_count
    subject_maps.where.not(subject_id: nil).count
  end

  def sync_status
    if sync_in_progress
      'in progress'
    elsif last_sync_successful.nil?
      'never'
    elsif last_sync_successful == false
      'failed'
    elsif last_sync_successful == true
      'successful'
    end
  end
end
