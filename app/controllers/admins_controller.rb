# frozen_string_literal: true

class AdminsController < ApplicationController
  before_action :authenticate_admin!

  def become
    user = User.find(become_admin_params)
    authorize user

    sign_in(:user, user)
    sign_out current_admin
    redirect_to root_url # or user_root_url
  end

  def show
    authorize current_admin
    @admins = Admin.order(:email)
    @minimum_admin_count_reached = Admin.count <= 1
  end

  def reset_password
    admin = Admin.find(params.expect(:id))
    authorize admin
    admin.send_reset_password_instructions
    redirect_to admin_path(current_admin), notice: "Password reset instructions sent to #{admin.email}"
  end

  def destroy
    admin = Admin.find(params.expect(:id))
    authorize admin
    if Admin.count <= 1
      redirect_to admin_path(current_admin), alert: 'There must be at least one admin account.'
    elsif admin == current_admin
      redirect_to admin_path(current_admin), alert: 'You cannot remove your own admin account.'
    else
      destroy_admin(admin)
    end
  end

  def reset_year
    authorize current_admin
    ResetYearJob.perform_later
    flash[:alert] = 'Reset Year Data'
    redirect_to schools_path
  end

  private

  def become_admin_params
    params.require(:user_id)
  end

  def destroy_admin(admin)
    admin.destroy
    redirect_to admin_path(current_admin), notice: "Removed admin account for #{admin.email}"
  end
end
