# frozen_string_literal: true

class HomeworksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[new]
  before_action :set_homework, only: %i[show destroy]
  rescue_from ActionController::ParameterMissing, with: :no_classroom_id

  def new
    @homework = Homework.new(due_date: 1.week.from_now, classroom: @classroom, required: 70)
    authorize @homework
    @lessons = Lesson.where(topic: @classroom.subject.topics).where('questions_count >= ?', 10)
  end

  def create
    @homework = Homework.new(homework_params)
    authorize @homework
    if @homework.save
      set_homework_notice
      redirect_to @homework
    else
      @classroom = @homework.classroom
      @classroom.present? ? render('new') : redirect_to(dashboard_path)
    end
  end

  def show
    authorize @homework
    @homework_progress = HomeworkProgress.includes(:user).where(homework: @homework).order('users.surname')
    @homework_counts = @homework.classroom.homework_counts.find_by(id: @homework)
  end

  def destroy
    authorize @homework
    redirect_to classroom_path(@homework.classroom)

    @homework.destroy
  end

  private

  def set_classroom
    @classroom = Classroom.find(new_homework_params[:classroom_id])
  end

  def set_homework
    @homework = Homework.find(params[:id])
  end

  def set_homework_notice
    flash[:notice] = if @homework.lesson.blank?
                       "#{@homework.topic.name} homework set"
                     else
                       "#{@homework.lesson.title} homework set"
                     end
  end

  def new_homework_params
    params.require(:classroom).permit(:classroom_id)
  end

  def homework_params
    params.require(:homework).permit(:due_date, :required, :topic_id, :classroom_id, :lesson_id)
  end

  def no_classroom_id
    flash[:alert] = 'Error! No classroom given when trying to create homework'
    redirect_to dashboard_path
  end
end
