# frozen_string_literal: true

namespace :maintainence do
  desc 'Run regular jobs'
  task regular_jobs: :environment do
    UpdateQuestionStatisticsJob.perform_later
  end
end
