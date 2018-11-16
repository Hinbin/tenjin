require 'wondeclient'
class AddSchool
  def initialize(client_token, school_id)
    @school_id = school_id
    @client_token = client_token
  end

  def call
    client = Wonde::Client.new(@client_token)
    school_from_client = client.schools.get(@school_id)

    PermittedSchool.create(school_id: @school_id, name: school_from_client.name, token: @client_token)
    School.from_wonde(school_from_client)
  end
end
