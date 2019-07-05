class AdminsController < ApplicationController
  before_action :authenticate_admin!

  def become
    authorize current_admin
    
    sign_in(:user, User.find(become_admin_params))
    sign_out current_admin
    redirect_to root_url # or user_root_url
  end

  private

  def become_admin_params
    params.require(:user_id)
  end
end
