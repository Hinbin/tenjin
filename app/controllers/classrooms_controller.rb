# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize current_user.school, :sync?
    @classrooms = policy_scope(Classroom).order(:name)
    @school = current_user.school
    @subjects = Subject.where(active: true)
  end

  def show
    @classroom = find_classroom
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: "student", enrollments: {classroom: @classroom})
    @homeworks = @classroom.homework_counts

    @homework_progress = HomeworkProgress.joins(:homework)
      .where(homework: @homeworks.pluck(:id))
      .order("homeworks.due_date desc")
  end

  def update
    classroom = authorize find_classroom
    classroom.update(subject_id: update_classroom_params[:subject])
    classroom.school.update(sync_status: "needed")
    head :no_content
  end

  private

  def find_classroom
    Classroom.find(params[:id])
  end

  def update_classroom_params
    params.permit(:subject, :id)
  end
end
