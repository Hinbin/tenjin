require 'wondeclient'
class School::SyncSchool
  def initialize(school)
    @school = school
    @client = Wonde::Client.new(school.token)
    @school_from_client = @client.schools.get(school.client_id)
    @school_api = @client.school(school.client_id)
  end

  def call
    return if @school.sync_status == 'syncing'

    School.from_wonde_sync_start(@school)
    fetch_api_data
    sync_all_data
    School.from_wonde_sync_end(@school)
  end

  def fetch_api_data
    # To limit API calls and improve performance - get all classroom and student data here
    @subject_data = @school_api.subjects.all
    @sync_data = @school_api.classes.all(%w[subject students employees])
    @deletion_data = @school_api.deletions.all
  end

  def sync_all_data
    SubjectMap.from_wonde(@school, @subject_data)
    Classroom.from_wonde(@school, @sync_data)
    User.from_wonde(@school, @sync_data, @school_api)
    Enrollment.from_wonde(@school, @sync_data)
  end
end
