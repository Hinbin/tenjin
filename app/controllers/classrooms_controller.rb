class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show update]

  def show
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: 'student', enrollments: { classroom: @classroom })
    @homeworks = Homework.includes(:homework_progresses).where(classroom: @classroom).order('homeworks.due_date desc')
    @homework_progress = HomeworkProgress.joins(:homework)
                                         .where(homework: @homeworks)
                                         .order('homeworks.due_date desc')
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end
end
