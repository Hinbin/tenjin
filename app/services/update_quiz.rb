# Takes a quiz, checks an incoming answer is correct and then
# updates to the next question.  Increments streak and answered correct counters
# Finally, checks to see if the quiz has finished and destroys as necessary.
class UpdateQuiz

  attr_accessor :quiz_finished

  def initialize(params)
    @answer = params[:answer]
    @quiz = params[:quiz]
    @quiz_finished = false
  end

  def call
    check_answer_correct
    move_to_next_question
    check_if_quiz_finished
    self
  end

  private

  def check_answer_correct
    answer_given = Answer.find_by(id: @answer)

    if answer_given.correct
      @quiz.answered_correct = @quiz.answered_correct + 1
      @quiz.streak = @quiz.streak + 1
    else
      @quiz.streak = 0
    end

    @quiz.save
  end

  def move_to_next_question
    @quiz.num_questions_asked = @quiz.num_questions_asked + 1
    @quiz.save
  end

  def check_if_quiz_finished
    return unless @quiz.num_questions_asked >= @quiz.questions_asked_id.length
    @quiz_finished = true
    @quiz.destroy
  end
end
