require 'wondeclient'
class AddSchool
  def initialize(client_token, school_id)
    @school_id = school_id
    @client = Wonde::Client.new(client_token)
    @school_from_client = @client.schools.get(school_id)
    @data_from_client = @client.school(school_id)
  end

  def call
    School.from_wonde(@school_from_client)
    SubjectMap.from_wonde(@data_from_client, @school_id)
  end
end
