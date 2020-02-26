# frozen_string_literal: true

class Quiz::CheckAnswer < ApplicationService
  def initialize(params)
    @quiz = params[:quiz]
    @question = params[:question]
    @asked_question = AskedQuestion.find_by(quiz: @quiz, question: @question)
    @answer_given = params[:answer_given]
  end

  def call
    check_answer_correct unless already_answered?

    Quiz::MoveQuizForward.call(quiz: @quiz)
    @quiz.save
    {
      answer: Answer.where(question: @question, correct: true),
      streak: @quiz.streak,
      answeredCorrect: @quiz.answered_correct,
      multiplier: Multiplier.where('score <= ?', @quiz.streak).order(id: :desc).pick(:multiplier)
    }
  end

  protected

  def already_answered?
    @asked_question.correct.present?
  end

  def check_answer_correct
    if @question.short_answer?
      check_short_answer
    else
      check_multiple_choice
    end
  end

  def check_short_answer
    answer_text = Answer.where(question_id: @question).pick(:text)
    return unless answer_text.present?

    if @answer_given[:short_answer].casecmp(answer_text)&.zero?
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def check_multiple_choice
    raise 'no valid answer given to multiple choice' if @answer_given[:id].blank?

    answer = Answer.where(id: @answer_given[:id]).pick(:correct)
    return unless answer.present?

    if answer
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def process_correct_answer
    @quiz.answered_correct += 1
    @quiz.streak += 1
    @asked_question.update_attribute(:correct, true)
    Quiz::AddLeaderboardPoint.call(quiz: @quiz, question: @question)
  end

  def process_incorrect_answer
    @quiz.streak = 0
    @asked_question.update_attribute(:correct, false)
  end
end
