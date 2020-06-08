# frozen_string_literal: true

# Moves the quiz to the next question.  If finished, set quiz as inactive
class Quiz::MoveQuizForward < ApplicationService
  def initialize(params)
    @quiz = params[:quiz]
  end

  def call
    move_to_next_question
    check_if_quiz_finished
  end

  private

  def move_to_next_question
    @quiz.num_questions_asked += 1
  end

  def check_if_quiz_finished
    return unless @quiz.num_questions_asked >= @quiz.questions.length

    @quiz.active = false
    Homework::UpdateHomeworkProgress.call(@quiz)
  end
end
