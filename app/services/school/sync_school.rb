# frozen_string_literal: true

require 'wondeclient'

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
    @client = Wonde::Client.new(school.token)
    @school_from_client = @client.schools.get(school.client_id)
    @school_api = @client.school(school.client_id)
  end

  def call
    # Assume timed out if more than two minutes syncing.  Adjust or put as env var?
    return if @school.sync_status == 'syncing' && (Time.now - School.first.updated_at) < 240

    School.from_wonde_sync_start(@school)
    fetch_class_data
    fetch_deletion_data
    School.from_wonde_sync_end(@school)
  end

  protected

  def fetch_class_data
    @school_api.classes.all(%w[students employees]).each do |data|
      @sync_data = data
      sync_all_data
    end
  end

  def fetch_deletion_data
    @deletion_data = @school_api.deletions.all
  end

  def sync_all_data
    classroom = Classroom.from_wonde(@school, @sync_data)

    User.from_wonde(@school, @sync_data, classroom)

    return unless classroom.subject.present?

    Enrollment.from_wonde(@sync_data)
  end
end
