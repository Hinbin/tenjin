class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show update]

  def show
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: 'student', enrollments: { classroom: @classroom })
    @homeworks = Homework.includes(:homework_progresses).where(classroom: @classroom)
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end
end
