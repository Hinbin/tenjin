# frozen_string_literal: true

namespace :daily_updates do
  desc 'Update counts'
  task update_counts: :environment do
    Classroom.find_each do |classroom|
      Classroom.reset_counters(classroom.id, :enrollments)
    end
  end
end
