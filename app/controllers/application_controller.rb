class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me, :school_id]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
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
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def find_dashboard_style
    style = ActiveCustomisation.joins(:customisation)
                               .where(user: current_user,
                                      customisations: { customisation_type: 'dashboard_style' }).first
    style.present? ? style.customisation.value : 'red'
  end
  
  def pundit_user
    return current_admin if current_admin.present?

    current_user
  end
end
