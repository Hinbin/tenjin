require 'wondeclient'
module PermittedSchoolsHelper
  def add_school(token, school_id)
    @client = Wonde::Client.new(token)
    @school = @client.schools.get(school_id)

    @school.name
  end
end
