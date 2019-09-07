class SyncSchoolJob < ApplicationJob
  queue_as :default

  def perform(school)
    School::SyncSchool.new(school).call
  end
end
