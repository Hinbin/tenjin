# frozen_string_literal: true

class HomeworksController < ApplicationController
  before_action :authenticate_user!
  rescue_from ActionController::ParameterMissing, with: :no_classroom_id

  def show
    @homework = authorize find_homework
    @homework_progress = HomeworkProgress.includes(:user).where(homework: @homework).order("users.surname")
    @homework_counts = @homework.classroom.homework_counts.find_by(id: @homework)
  end

  def new
    @classroom = find_classroom
    @homework = Homework.new(due_date: 1.week.from_now, classroom: @classroom, required: 70)
    authorize @homework
    @lessons = lessons_for_classroom(@classroom)
  end

  def create
    @homework = Homework.new(homework_params)
    authorize @homework
    if @homework.save
      flash[:notice] = homework_notice(@homework)
      redirect_to @homework
    else
      @classroom = @homework.classroom
      if @classroom.present?
        @lessons = lessons_for_classroom(@classroom)
        render(:new)
      else
        redirect_to(dashboard_path)
      end
    end
  end

  def destroy
    homework = authorize find_homework
    classroom = homework.classroom
    homework.destroy
    redirect_to classroom_path(classroom)
  end

  private

  def find_classroom
    Classroom.find(new_homework_params[:classroom_id])
  end

  def find_homework
    Homework.find(params[:id])
  end

  def homework_notice(homework)
    if homework.lesson.blank?
      "#{homework.topic.name} homework set"
    else
      "#{homework.lesson.title} homework set"
    end
  end

  def new_homework_params
    params.require(:classroom).permit(:classroom_id)
  end

  def homework_params
    params.require(:homework).permit(:due_date, :required, :topic_id, :classroom_id, :lesson_id)
  end

  def lessons_for_classroom(classroom)
    Lesson.where(topic: classroom.subject.topics).where(questions_count: 10..)
  end

  def no_classroom_id
    flash[:alert] = "Error! No classroom given when trying to create homework"
    redirect_to dashboard_path
  end
end
