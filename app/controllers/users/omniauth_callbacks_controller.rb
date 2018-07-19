class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    # persisted? means if the record already existed (or hasn't been deleted)
    # So this effectively prevents a new record from being created if an 
    # e-mail has not been found.
    
    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:notice] = 'Your account has not been found'
      redirect_to '/users/sign_in'
    end
  end
end
