# frozen_string_literal: true

# Finds the correct quiz for a user if multiple quizzes have been created.
class Quiz::SelectCorrectQuiz < ApplicationService
  def initialize(params)
    @quizzes = params[:quizzes]
  end

  def call
    if @quizzes.length.zero?
      '/quizzes/new'
    elsif @quizzes.length == 1
      @quizzes.first
    else
      deactivate_old_quizzes
      # Return the last, active record.
      @quizzes.where(active: true).first
    end
  end

  protected

  def deactivate_old_quizzes
    # Get every quiz, apart from the last one...
    @quizzes.order(created_at: :desc).drop(1).each do |quiz|
      # Check if no questions have been asked, if so delete it
      # Deactive each quiz.
      if quiz.num_questions_asked.zero?
        quiz.delete
      else
        quiz.active = false
        quiz.save
      end
    end
  end
end
