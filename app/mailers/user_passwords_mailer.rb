# frozen_string_literal: true

class UserPasswordsMailer < ApplicationMailer
  default from: ENV['DEFAULT_MAIL_SENDER']

  def user_passwords_email
    @user = params[:user]
    @csv = params[:csv]
    attachments['tenjin_passwords.csv'] = { mime_type: 'text/csv', content: @csv }
    make_bootstrap_mail(to: @user.email, subject: 'Tenjin User Passwords')
  end
end
