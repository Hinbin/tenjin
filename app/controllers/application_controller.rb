# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me school_id]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def after_sign_in_path_for(resource)
    resource.is_a?(Admin) ? schools_path : dashboard_path
  end

  private

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def find_dashboard_style
    style = ActiveCustomisation.joins(:customisation)
                               .find_by(user: current_user,
                                        customisations: { customisation_type: 'dashboard_style' })
    return style.customisation if style.present?

    Customisation.find_by(customisation_type: 'dashboard_style', value: 'red')
  end

  def pundit_user
    admin_signed_in? ? current_admin : current_user
  end
end
