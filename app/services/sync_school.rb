require 'wondeclient'
class SyncSchool
  def initialize(school_id)
    @school_id = school_id
    @school = PermittedSchool.find_by(school_id: school_id)
    @client = Wonde::Client.new(@school.token)
    @school_from_client = @client.schools.get(school_id)
    @data_from_client = @client.school(school_id)
  end

  def call
    # To limit API calls and improve performance - get all classroom and student data here
    subject_data = @data_from_client.subjects.all
    sync_data = @data_from_client.classes.all(%w[subject students])
    SubjectMap.from_wonde(@school_from_client, subject_data)
    Classroom.from_wonde(@school_from_client, sync_data)
  end
end
