# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: ENV.fetch('DEFAULT_MAIL_SENDER', nil)

  def setup_email
    @user = params[:user]
    @password = params[:password]
    mail(to: @user.email, subject: 'Welcome to Tenjin')
  end
end
