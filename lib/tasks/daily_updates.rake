# frozen_string_literal: true

namespace :daily_updates do
  desc 'Update counts'
  task update_counts: :environment do
    Classroom.find_each do |classroom|
      Classroom.reset_counters(classroom.id, :enrollments)
    end

    Question.find_each do |q|
      Question.reset_counters(q.id, :flagged_questions)
    end

    Lesson.find_each do |l|
      Lesson.reset_counters(l.id, :questions)
    end
  end
end
