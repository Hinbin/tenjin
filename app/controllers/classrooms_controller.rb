# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show update]

  def show
    authorize @classroom
    @students = User.joins(enrollments: :classroom).where(role: 'student', enrollments: { classroom: @classroom })
    @homeworks = homeworks

    @homework_progress = HomeworkProgress.joins(:homework)
                                         .where(homework: @homeworks.pluck(:id))
                                         .order('homeworks.due_date desc')
  end

  def index
    authorize current_user.school, :sync?
    @classrooms = policy_scope(Classroom).order(:name)
    @school = current_user.school
    @subjects = Subject.all
  end

  def update
    authorize @classroom
    @classroom.update(subject_id: update_classroom_params[:subject])
    @classroom.school.update(sync_status: 'needed')
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def update_classroom_params
    params.permit(:subject, :id)
  end

  def homeworks
    h_count = HomeworkProgress.arel_table[:id].count
    h_count_completed = Arel::Nodes::Case.new HomeworkProgress.arel_table[:completed]
    h_count_completed.when(true).then(1).else(0)

    topic_name = Topic.arel_table[:name]
    Homework.select(:id, h_count, h_count_completed.sum.as('completed_count'), :due_date, :topic_id, topic_name)
            .joins(:homework_progresses, :topic)
            .group(:id, topic_name)
            .where(classroom: @classroom)
  end
end