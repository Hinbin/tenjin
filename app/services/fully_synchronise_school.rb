require 'wondeclient'
class FullySynchroniseSchool
  def initialize(client_token, school_id)
    @client = Wonde::Client.new(client_token)
    @school_from_client = @client.schools.get(school_id)
  end

  def call
    @school_from_database = School.from_wonde(@school_from_client)
  end
end