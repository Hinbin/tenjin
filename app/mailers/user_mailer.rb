# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: ENV['DEFAULT_EMAIL_FROM']

  def setup_email
    @user = params[:user]
    @password = params[:password]
    make_bootstrap_mail(to: @user.email, subject: 'Welcome to Tenjin')
  end
end
