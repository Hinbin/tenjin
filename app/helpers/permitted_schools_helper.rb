require 'wondeclient'
module PermittedSchoolsHelper
  def add_school(token, school_id)
    create_school = AddSchool.new(token, school_id)
    create_school.call

    sync_school = SyncSchool.new(school_id)
    sync_school.call
  end
end
