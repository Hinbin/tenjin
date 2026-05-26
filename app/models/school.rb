# frozen_string_literal: true

class School < ApplicationRecord
  belongs_to :school_group, optional: true
  has_many :classrooms
  has_many :users

  validates :client_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :token, presence: true

  enum sync_status: {never: 0, queued: 1, syncing: 2, successful: 3, failed: 4, needed: 5}

  def self.from_wonde(client_school, token)
    school = where(client_id: client_school.id).first_or_initialize
    school.name = client_school.name
    school.token = token
    school.sync_status = :never
    school.save!
    school
  end

  def start_sync
    update!(sync_status: :syncing)

    User.where(school: self)
      .where.not(id: User.with_role(:school_admin))
      .update_all(disabled: true)
    Enrollment.joins(:classroom)
      .where(classrooms: {school_id: id})
      .destroy_all
    Classroom.where(school: self)
      .update_all(disabled: true)
  end

  def finish_sync
    User.where(school: self, role: :employee)
      .where.not(id: Enrollment.joins(:classroom).where(classrooms: {school_id: id}).select(:user_id))
      .update_all(disabled: true)

    update!(sync_status: :successful)
  end
end
