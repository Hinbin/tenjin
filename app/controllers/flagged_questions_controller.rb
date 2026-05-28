# frozen_string_literal: true

class FlaggedQuestionsController < ApplicationController
  before_action :authenticate_user!

  def create
    flagged_question = FlaggedQuestion.where(question_id: create_flagged_question_params[:question_id], user: current_user).first_or_initialize
    authorize flagged_question
    if flagged_question.persisted?
      flagged_question.destroy
    else
      flagged_question.save
    end
    head :ok
  end

  private

  def create_flagged_question_params
    params.require(:flagged_question).permit(:question_id)
  end
end
