# frozen_string_literal: true

class UsageStatistic::RecordQuizStart < ApplicationService
  def initialize(quiz)
    super()
    @quiz = quiz
  end

  def call
    statistic = UsageStatistic.where(user: @quiz.user,
                                     topic: @quiz.topic,
                                     lesson: @quiz.lesson,
                                     date: Date.current).first_or_create!

    UsageStatistic.where(id: statistic.id)
                  .update_all('quizzes_started = COALESCE(quizzes_started, 0) + 1, updated_at = CURRENT_TIMESTAMP')
  end
end
