# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize current_user
    @students = policy_scope(User).includes(enrollments: [:classroom]).where(role: "student")

    return unless current_user.has_role? :school_admin

    @employees = policy_scope(User)
      .includes(enrollments: [:classroom])
      .where(role: "employee")
  end

  def show
    @user = authorize find_user
    @dashboard_style = find_dashboard_style
    @homeworks = policy_scope(Homework)
    @homework_progress = HomeworkProgress.includes(:homework, homework: [{topic: :subject}])
      .where(homework: @homeworks, user: @user)
  end

  def update
    user = authorize find_user
    user.password = update_password_params[:password]
    user.save
    redirect_to user, notice: "Password successfully updated"
  end

  def reset_password
    user = authorize find_user
    new_password = Devise.friendly_token(6)
    user.reset_password(new_password, new_password)
    user.save
    render json: {id: user.id, password: new_password}
  end

  def unlink_oauth_account
    user = authorize find_user
    user.update(oauth_uid: "", oauth_email: "", oauth_provider: "")

    redirect_to user
  end

  private

  def update_password_params
    params.require(:user).permit(:password)
  end

  def find_user
    User.find(params[:id])
  end
end
