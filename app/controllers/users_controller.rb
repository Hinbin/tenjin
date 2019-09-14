class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:set_role]
  before_action :authenticate_admin!, only: [:set_role]

  def index
    authorize current_user
    @students = policy_scope(User).where(role: 'student')
    @employees = policy_scope(User).where(role: 'employee').or(policy_scope(User).where(role: 'school_admin')) if @current_user.school_admin?
  end

  def show
    @css_flavour = find_dashboard_style
    @user = User.find(params[:id])
    authorize @user
    @homeworks = policy_scope(Homework)
    find_homework_progress
  end

  def set_role
    return unless update_user_role_params[:role].present? && update_user_role_params[:id].present?

    user = User.find(update_user_role_params[:id])
    authorize user, :set_role?
    user.update_attribute('role', update_user_role_params[:role])
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

  def update_user_role_params
    params.permit(:role, :id)
  end

 
end
