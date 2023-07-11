# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show update]

  def show
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: 'student', enrollments: { classroom: @classroom })
    @homeworks = @classroom.homework_counts

    @homework_progress = HomeworkProgress.joins(:homework)
                                         .where(homework: @homeworks.pluck(:id))
                                         .order('homeworks.due_date desc')
  end

  def index
    authorize current_user.school, :sync?
    @classrooms = policy_scope(Classroom).order(:name)
    @school = current_user.school
    @subjects = Subject.where(active: true)
  end

  def update
    authorize @classroom
    @classroom.update(subject_id: update_classroom_params[:id])
    @classroom.school.update(sync_status: 'needed')
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def update_classroom_params
    params.require(:subject).permit(:id)
  end
end
