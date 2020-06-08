# frozen_string_literal: true

class Homework::UpdateHomeworkProgress < ApplicationService
  def initialize(quiz)
    @quiz = quiz
  end

  def call
    completed_homework = false
    homework_progresses.find_each do |progress|
      check_percentage_correct(progress)
    end
    OpenStruct.new(success?: true, completed?: completed_homework, errors: nil)
  end

  protected

  def homework_progresses
    HomeworkProgress.includes(:homework, :topic).where(user: @quiz.user)
  end

  def check_percentage_correct(progress)
    return unless @quiz.topic == progress.topic

    check_progress_percentage(@quiz.answered_correct.to_f / @quiz.num_questions_asked, progress)
  end

  def check_progress_percentage(percentage, progress)
    percentage *= 100
    progress.progress = percentage if percentage > progress.progress
    progress.completed = true if progress.progress >= progress.homework.required && progress.completed == false
    progress.save if progress.changed?
  end
end
