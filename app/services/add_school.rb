require 'wondeclient'
class AddSchool
  def initialize(school_params)
    @school_id = school_params[:client_id]
    @client_token = school_params[:token]
  end

  def call
    client = Wonde::Client.new(@client_token)
    school_from_client = client.schools.get(@school_id)
    school = School.from_wonde(school_from_client, @client_token)
    school.permitted = true
    school
  end
end
