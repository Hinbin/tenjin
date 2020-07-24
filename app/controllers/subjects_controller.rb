# frozen_string_literal: true
class SubjectsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_subject, only: %i[show update]

  def index
    @subjects = policy_scope(Subject).order(:name)
  end

  def show
    authorize @subject
  end

  def update
    authorize @subject
    @subject.update_attributes(subject_params)
    redirect_to @subject
  end

  private

  def set_subject
    @subject = Subject.find(params[:id])
  end

  def subject_params
    params.require(:subject).permit(:name)
  end

end
