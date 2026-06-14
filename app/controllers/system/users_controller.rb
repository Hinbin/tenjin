# frozen_string_literal: true

module System
  class UsersController < BaseController
    def set_role
      role = set_user_role_params[:role]
      return if role.blank?

      user = authorize find_user
      User::ChangeUserRole.call(user, role, :add, set_user_role_params[:subject])
      redirect_to manage_roles_system_users_path(school: user.school)
    end

    def remove_role
      role = set_user_role_params[:role]
      return if role.blank?

      user = authorize find_user
      User::ChangeUserRole.call(user, role, :remove, set_user_role_params[:subject])
      redirect_to manage_roles_system_users_path(school: user.school)
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

    def find_user
      User.find(params[:id])
    end

    def set_user_role_params
      params.require(:user).permit(:role, :subject, :id)
    end

    def update_email_params
      params.require(:user).permit(:email)
    end

    def manage_roles_params
      params.permit(:school)
    end
  end
end
