# frozen_string_literal: true

class FlaggedQuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_flagged_question, only: [:destroy]
  before_action :set_flagged_question_variables, only: %i[create]

  def create
    if @flagged_question.persisted?
      @flagged_question.destroy
    else
      @flagged_question.save
    end

    render partial: 'quizzes/flagged_question_icon'
  end

  private

  def set_flagged_question_variables
    @flagged_question = FlaggedQuestion.where(create_flagged_question_params).first_or_initialize
    @question = Question.find(create_flagged_question_params[:question_id])
    authorize @flagged_question
  end

  def create_flagged_question_params
    params.require(:flagged_question).permit(:user_id, :question_id)
  end
end
