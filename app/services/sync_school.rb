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
    sync_data = @data_from_client.classes.all(%w[subject students])
    SubjectMap.from_wonde(@school_from_client, @data_from_client)
    Classroom.from_wonde(@school_from_client, sync_data)
  end
end
