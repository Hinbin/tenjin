# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, except: %i[set_role manage_roles remove_role]
  before_action :authenticate_admin!, only: %i[set_role manage_roles remove_role]
  before_action :set_user, only: %i[show update reset_password set_role remove_role]

  def index
    authorize current_user
    @students = policy_scope(User).includes(enrollments: [:classroom]).where(role: 'student')

    return unless @current_user.has_role? :school_admin

    @employees = policy_scope(User)
                 .includes(enrollments: [:classroom])
                 .where(role: 'employee')
  end

  def show
    @css_flavour = find_dashboard_style
    authorize @user
    @homeworks = policy_scope(Homework)
    find_homework_progress
  end

  def set_role
    return unless set_user_role_params[:role].present?

    role = set_user_role_params[:role]
    authorize @user

    if role == 'school_admin'
      @user.add_role role
    elsif %w[question_author lesson_author].include? role
      @user.add_role role, Subject.find(set_user_role_params[:subject])
    end

    redirect_to manage_roles_users_path(school: @user.school)
  end

  def remove_role
    return unless set_user_role_params[:role].present?

    role = set_user_role_params[:role]
    authorize @user

    if role == 'school_admin'
      @user.remove_role role
    elsif %w[question_author lesson_author].include? role
      @user.remove_role role, Subject.find(set_user_role_params[:subject])
    end

    redirect_to manage_roles_users_path(school: @user.school)
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

  def manage_roles
    authorize current_admin
    if manage_roles_params[:school].present?
      @school = School.find(manage_roles_params[:school])
      @employees = User.where(school: @school, role: 'employee')
      @school_admins = User.with_role :school_admin, @school
    end

    @lesson_authors = User.with_role :lesson_author, :any
    @question_authors = User.with_role :question_author, :any
    @all_subjects = Subject.all
    render 'manage_roles'
  end

  private

  def find_homework_progress
    @homework_progress = HomeworkProgress.includes(:homework, homework: [topic: :subject])
                                         .where(homework: @homeworks, user: @user)
  end

  def update_password_params
    params.require(:user).permit(:password)
  end

  def set_user_role_params
    params.require(:user).permit(:role, :subject, :id)
  end

  def manage_roles_params
    params.permit(:school)
  end

  def set_user
    @user = User.find(params[:id])
  end
end
