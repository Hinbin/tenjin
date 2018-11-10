class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show]

  def show
    authorize @classroom
  end

  private

  def set_classroom
    @classroom = Classroom.find(classroom_params[:id])
  end

  def classroom_params
    params.permit(:id)
  end

  def check_access
  end
end
