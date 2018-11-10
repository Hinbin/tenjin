require 'wondeclient'
module PermittedSchoolsHelper
  def addSchool(token, schoolID)
    #'2a550dc912f6a63488af42352b79c5961e87daf9'
    #'A852030759'

    @client = Wonde::Client.new(token)
    @school = @client.schools.get(schoolID)

    @school.name
  end
end