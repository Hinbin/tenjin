# Moves the quiz to the next question.  If finished, set quiz as inactive
class Quiz::MoveQuizForward
  def initialize(params)
    @quiz = params[:quiz]
  end

  def call
    move_to_next_question
    check_if_quiz_finished
  end

  private

  def move_to_next_question
    Challenge::UpdateChallengeProgress.new(@quiz, 'streak').call

    @quiz.num_questions_asked = @quiz.num_questions_asked + 1
    @quiz.save
  end

  def check_if_quiz_finished
    return unless @quiz.num_questions_asked >= @quiz.questions.length

    @quiz.active = false
    Challenge::UpdateChallengeProgress.new(@quiz, 'number_correct').call
    Homework::UpdateHomeworkProgress.new(@quiz).call

    @quiz.save
  end
end
