class HomeworksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[new]
  before_action :set_homework, only: %i[show destroy]
  rescue_from ActionController::ParameterMissing, with: :no_classroom_id

  def new
    @homework = Homework.new(due_date: Time.now + 1.week, classroom: @classroom, required: 70)
    authorize @homework
  end

  def create
    @homework = Homework.new(homework_params)
    authorize @homework
    if @homework.save
      redirect_to @homework
    else
      @classroom = @homework.classroom
      @classroom.present? ? render('new') : redirect_to(dashboard_path)
    end
  end

  def show
    authorize @homework
    @homework_progress = HomeworkProgress.includes(:user).where(homework: @homework).order('users.surname')
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

  def new_homework_params
    params.require(:classroom).permit(:classroom_id)
  end

  def homework_params
    params.require(:homework).permit(:due_date, :required, :topic_id, :classroom_id)
  end

  def no_classroom_id
    flash[:alert] = 'Error! No classroom given when trying to create homework'
    redirect_to dashboard_path
  end
end
