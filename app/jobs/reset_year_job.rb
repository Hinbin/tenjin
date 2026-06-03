# frozen_string_literal: true

class ResetYearJob < ApplicationJob
  queue_as :default

  def perform
    Admin::ResetYear.call
  end
end
