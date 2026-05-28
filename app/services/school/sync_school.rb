# frozen_string_literal: true

require "wondeclient"

class School::SyncSchool < ApplicationService
  def initialize(school)
    @school = school
    @client = Wonde::Client.new(school.token)
    @school_api = @client.school(school.client_id)
  end

  def call
    # Assume timed out if more than two minutes syncing.  Adjust or put as env var?
    return if @school.sync_status == "syncing" && (Time.current - @school.updated_at) < 240

    @school.start_sync
    fetch_class_data
    @school.finish_sync
  end

  protected

  def fetch_class_data
    @school_api.classes.all(%w[students employees]).each do |data|
      @sync_data = data
      sync_all_data
    end
  end

  def sync_all_data
    classroom = Classroom.from_wonde(@school, @sync_data)

    User.from_wonde(@school, @sync_data, classroom)

    return if classroom.subject.blank?

    Enrollment.from_wonde(@sync_data)
  end
end
