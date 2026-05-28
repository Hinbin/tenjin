# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, except: %i[set_role manage_roles remove_role update_email send_welcome_email]
  before_action :authenticate_admin!, only: %i[set_role manage_roles remove_role update_email send_welcome_email]

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

  def set_role
    role = set_user_role_params[:role]
    return if role.blank?

    user = authorize find_user

    User::ChangeUserRole.call(user, role, :add, set_user_role_params[:subject])
    redirect_to manage_roles_users_path(school: user.school)
  end

  def remove_role
    role = set_user_role_params[:role]
    return if role.blank?

    user = authorize find_user

    User::ChangeUserRole.call(user, role, :remove, set_user_role_params[:subject])

    redirect_to manage_roles_users_path(school: user.school)
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

  def manage_roles
    authorize current_admin
    if manage_roles_params[:school].present?
      @school = School.find(manage_roles_params[:school])
      @employees = User.where(school: @school, role: "employee")
    end

    @school_admins = User.includes(:school).with_role :school_admin
    @lesson_authors = User.with_role :lesson_author, :any
    @question_authors = User.with_role :question_author, :any
    @all_subjects = Subject.where(active: true)

    render "manage_roles"
  end

  def unlink_oauth_account
    user = authorize find_user
    user.update(oauth_uid: "", oauth_email: "", oauth_provider: "")

    redirect_to user
  end

  def update_email
    @user = authorize find_user
    @user.email = update_email_params[:email]
    @user.save

    flash.now[:notice] = "Updated email to #{@user.forename} #{@user.surname}"

    render template: "shared/flash"
  end

  def send_welcome_email
    @user = authorize find_user
    flash.now[:notice] = "Setup email sent to #{@user.forename} #{@user.surname} (#{@user.email})"

    UserMailer.with(user: @user).setup_email.deliver_later
    @user.send_reset_password_instructions

    render template: "shared/flash"
  end

  private

  def update_password_params
    params.require(:user).permit(:password)
  end

  def update_email_params
    params.require(:user).permit(:email)
  end

  def set_user_role_params
    params.require(:user).permit(:role, :subject, :id)
  end

  def manage_roles_params
    params.permit(:school)
  end

  def find_user
    User.find(params[:id])
  end
end
