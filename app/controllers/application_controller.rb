class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:school_id])
  end

  def after_sign_in_path_for(resource)
    if resource.class == User
      dashboard_path
    elsif resource.class == Admin
      questions_path
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
