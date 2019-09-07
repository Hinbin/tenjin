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
    fetch_subject_data
    fetch_class_data
    fetch_deletion_data
    School.from_wonde_sync_end(@school)
  end

  def fetch_subject_data
    @subject_data = @school_api.subjects.all
    SubjectMap.from_wonde(@school, @subject_data)
  end

  def fetch_class_data
    # To limit API calls and improve performance - get all classroom and student data here
    @school_api.classes.all(%w[subject students employees]).each do |data|
      @sync_data = data
      sync_all_data
    end
  end

  def fetch_deletion_data
    @deletion_data = @school_api.deletions.all
  end

  def sync_all_data
    Classroom.from_wonde(@school, @sync_data)
    User.from_wonde(@school, @sync_data, @school_api)
    Enrollment.from_wonde(@school, @sync_data)
  end
end
