# frozen_string_literal: true

class SyncSchoolJob < ApplicationJob
  queue_as :default

  def perform(school)
    School::SyncSchool.call(school)
  end
end
