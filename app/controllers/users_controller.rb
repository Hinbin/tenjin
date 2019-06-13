class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize current_user
    @students = policy_scope(User).where(role: 'student')
  end

  def show
    authorize current_user
    @css_flavour = find_dashboard_style
    @user = User.find(params[:id])
    @homeworks = policy_scope(Homework)
    find_homework_progress
  end

  def update
    user_record = User.find(params[:id])
    authorize user_record
    user_record.password = update_password_params[:password]
    user_record.save
    redirect_to user_record, notice: 'Password successfully updated'
  end

  private

  def find_homework_progress
    @homework_progress = HomeworkProgress.includes(:homework, homework: [topic: :subject])
                                         .where(homework: @homeworks, user: @user)
  end

  def update_password_params
    params.require(:user).permit(:password)
  end
end
