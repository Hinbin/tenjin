# Takes a quiz, checks an incoming answer is correct and then
# updates to the next question.  Increments streak and answered correct counters
# Finally, checks to see if the quiz has finished and destroys as necessary.
class UpdateQuiz
  def initialize(params)
    @answer = params[:answer]
    @quiz = params[:quiz]
    @question = params[:question]
    @asked_question = @question.asked_questions.first
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
      @asked_question.correct = true
    else
      @quiz.streak = 0
      @asked_question.correct = false
    end

    @asked_question.save
    @question.save
  end

  def move_to_next_question
    @quiz.num_questions_asked = @quiz.num_questions_asked + 1
    @quiz.save
  end

  def check_if_quiz_finished
    return unless @quiz.num_questions_asked >= @quiz.questions.length
    @quiz.active = false
    @quiz.save
  end
end
