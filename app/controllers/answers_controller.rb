# frozen_string_literal: true

class AnswersController < ApplicationController
  before_action :authenticate_user!

  def new
    question = Question.find(new_answer_params[:question_id])
    return if question.blank?

    authorize question.topic
    answer = Answer.create(question: question, correct: false)
    answer.update_attribute(:correct, true) if question.question_type == "short_answer"

    redirect_to question
  end

  def update
    answer = find_answer
    authorize answer.question.topic
    answer.update(answer_params)
  end

  def destroy
    answer = find_answer
    authorize answer.question.topic
    answer.destroy

    redirect_to answer.question
  end

  private

  def find_answer
    Answer.find(params[:id])
  end

  def new_answer_params
    params.require(:question).permit(:question_id)
  end

  def answer_params
    params.require(:answer).permit(:text, :correct)
  end
end
