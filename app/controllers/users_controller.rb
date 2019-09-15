class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:set_role]
  before_action :authenticate_admin!, only: [:set_role]
  before_action :set_user, only: %i[show update reset_password set_role]

  def index
    authorize current_user
    @students = policy_scope(User).where(role: 'student')

    return unless @current_user.school_admin?

    @employees = policy_scope(User).where(role: 'employee').or(policy_scope(User).where(role: 'school_admin'))
  end

  def show  
    @css_flavour = find_dashboard_style
    authorize @user
    @homeworks = policy_scope(Homework)
    find_homework_progress
  end

  def set_role
    return unless update_user_role_params[:role].present?

    authorize @user, :set_role?
    @user.update_attribute('role', update_user_role_params[:role])
  end

  def update
    authorize @user
    @user.password = update_password_params[:password]
    @user.save
    redirect_to @user, notice: 'Password successfully updated'
  end

  def reset_password
    authorize @user
    new_password = Devise.friendly_token(6)
    @user.reset_password(new_password, new_password)
    @user.save
    render json: { id: @user.id, password: new_password }
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

  def set_user
    @user = User.find(params[:id])
  end
end
