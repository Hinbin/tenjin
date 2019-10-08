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

  def deactivate_old_quizzes
    # Get every quiz, apart from the last one...
    @quizzes.order(:id).reverse_order.drop(1).each do |quiz|
      # Deactive each quiz.  Check if no questions have been asked, if so delete it
      quiz.active = false
      quiz.save
      quiz.delete if quiz.num_questions_asked.zero?
    end
  end
end
