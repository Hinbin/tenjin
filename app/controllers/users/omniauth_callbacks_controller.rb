# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def wonde
    auth = request.env["omniauth.auth"]
    return fail_sign_in if auth.blank?

    user = User.from_omniauth(auth)
    attempt_user_sign_in(user)
  end

  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"], current_user)

    if current_user.present?
      flash[:notice] = "Successfully linked Google account"
      redirect_to dashboard_path
    else
      attempt_user_sign_in(@user)
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    end
  end

  def attempt_user_sign_in(user)
    if user.blank?
      fail_sign_in
    elsif user.persisted?
      sign_in_and_redirect user, event: :authentication
    else
      fail_sign_in
    end
  end

  def fail_sign_in
    flash[:alert] = "Your account has not been found"
    redirect_to "/"
  end
end
