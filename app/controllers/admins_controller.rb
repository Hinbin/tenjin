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
end
