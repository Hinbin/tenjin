# Finds the correct quiz for a user if multiple quizzes have been created.
class SelectCorrectQuiz
  def initialize(params)
    @quizzes = params[:quizzes]
  end

  def call
    # Get every quiz, apart from the last one...
    @quizzes.reverse_order.drop(1).each do |quiz|
      # Deactive each quiz.  Check if no questions have been asked, if so delete it
      quiz.active = false
      quiz.save
      quiz.delete if quiz.num_questions_asked.zero?
    end
    # Return the last, active record.
    @quizzes.last
  end
end
