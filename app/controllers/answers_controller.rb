class AnswersController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_answer, only: %i[show update destroy]

  def new
    @question = Question.find(new_answer_params[:question_id])
    return unless @question.present?

    authorize @question.topic
    @answer = Answer.create(question: @question, text: 'Click here to edit answer', correct: false)
    @answer.update_attribute(:correct, true) if @question.question_type == 'short_answer'

    redirect_to @question
  end

  def update
    authorize @answer.question.topic
    @answer.update(answer_params)

    @answer.save
  end

  def destroy
    authorize @answer.question.topic
    @answer.destroy

    redirect_to @answer.question
  end

  private

  def set_answer
    @answer = Answer.find(params[:id])
  end

  def new_answer_params
    params.require(:question).permit(:question_id)
  end

  def answer_params
    params.require(:answer).permit(:text, :correct)
  end

end
