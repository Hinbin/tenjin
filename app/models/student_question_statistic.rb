# frozen_string_literal: true

# Persistent per-student-per-question performance rollup. Survives the daily purge of
# asked_questions (UpdateQuestionStatisticsJob) and underpins per-student gap analysis.
class StudentQuestionStatistic < ApplicationRecord
  belongs_to :user
  belongs_to :question
end
