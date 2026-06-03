# frozen_string_literal: true

namespace :migrations do
  desc 'Migrate data'
  task usage_statistic_questions: :environment do
    # Set start date for collecting statistics to the start of the year.
    start_date = Date.new(2020, 1, 6)
    UsageStatistic.find_each do |us|
      ActiveRecord::Base.Transaction do
        user_statistic = UserStatistic.create_or_find_by(
          user: us.user,
          week_beginning: start_date
        )
        user_statistic.increment!(:questions_answered, us.questions_answered) if us.questions_answered.present?
      end
    end
  end
end
