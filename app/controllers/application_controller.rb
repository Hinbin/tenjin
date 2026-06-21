# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_preview_customisation, :cosmetic_trial_open?, :cosmetic_trial_retry_in

  protected

  # The customisation the user is currently trying live (try-before-you-buy), or nil. Session-scoped
  # and validated previewable so a stale/invalid id can never leak into the rendered theme.
  def current_preview_customisation
    return @current_preview_customisation if defined?(@current_preview_customisation)

    id = session[:preview_customisation_id]
    record = id && Customisation.find_by(id: id)
    @current_preview_customisation = record&.previewable? ? record : nil
  end

  # Can the student act on a "Try it" button now? True while a trial is already running (so they can
  # switch looks) or once the cooldown has lifted. Drives whether the button or a cooldown hint shows.
  def cosmetic_trial_open?
    current_preview_customisation.present? || !!current_user&.cosmetic_trial_available?
  end

  # Human-readable time until the next trial can be started (e.g. "about 1 hour").
  def cosmetic_trial_retry_in
    available_at = current_user&.cosmetic_trial_available_at
    available_at ? helpers.distance_of_time_in_words(Time.current, available_at) : 'now'
  end

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
    redirect_to(request.referer || root_path)
  end

  def pundit_user
    admin_signed_in? ? current_admin : current_user
  end
end
