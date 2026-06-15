# frozen_string_literal: true

class Quiz::CheckAnswer < ApplicationCommand
  def initialize(quiz:, question:, answer_given:)
    @quiz = quiz
    @question = question
    @asked_question = AskedQuestion.find_by(quiz: @quiz, question: @question)
    @answer_given = answer_given
  end

  def call
    return failure(:no_answer_provided) if blank_answer?

    check_answer_correct unless already_answered?

    Quiz::MoveQuizForward.call(quiz: @quiz)
    @quiz.save

    success(Quiz::CheckAnswerOutcome.new(
      question: @question,
      streak: @quiz.streak,
      answered_correct: @quiz.answered_correct,
      multiplier: Multiplier.for_streak(@quiz.streak)
    ))
  end

  private

  def blank_answer?
    !@question.short_answer? && @answer_given[:id].blank?
  end

  def already_answered?
    !@asked_question.correct.nil?
  end

  def check_answer_correct
    @question.short_answer? ? check_short_answer : check_multiple_choice
  end

  def check_short_answer
    answer_text = Answer.where(question_id: @question).pick(:text)
    return if answer_text.blank?

    if @answer_given[:short_answer].casecmp(answer_text)&.zero?
      process_correct_answer
    else
      process_incorrect_answer
    end
  end

  def check_multiple_choice
    answer = Answer.where(id: @answer_given[:id]).pick(:correct)
    return if answer.nil?

    answer ? process_correct_answer : process_incorrect_answer
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
