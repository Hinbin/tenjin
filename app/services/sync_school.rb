require 'wondeclient'
class SyncSchool
  def initialize(school_id)
    @school_id = school_id
    @school = School.find_by(client_id: school_id)
    @client = Wonde::Client.new(@school.token)
    @school_from_client = @client.schools.get(school_id)
    @data_from_client = @client.school(school_id)
  end

  def call
    # To limit API calls and improve performance - get all classroom and student data here
    subject_data = @data_from_client.subjects.all
    sync_data = @data_from_client.classes.all(%w[subject students employees])
    school = School.school_from_client_id(@school_from_client.id)
    SubjectMap.from_wonde(school, subject_data)
    Classroom.from_wonde(school, sync_data)
    User.from_wonde(school, sync_data)
    Enrollment.from_wonde(school, sync_data)
  end
end
