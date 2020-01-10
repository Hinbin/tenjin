# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: 'tenjin@outwood.com'

  def setup_email
    @user = params[:user]
    @password = params[:password]
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end
