# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    block.call
  rescue StandardError => e
    AppErrorReporter.report(e, job:)
    raise
  end
end
