# frozen_string_literal: true

class UserPasswordsMailer < ApplicationMailer
  default from: ENV['DEFAULT_MAIL_SENDER']

  def user_passwords_email
    @user = params[:user]
    @student_csv = params[:student_csv]
    @teacher_csv = params[:teacher_csv]
    attachments['student_passwords.csv'] = { mime_type: 'text/csv', content: @student_csv }
    attachments['teacher_passwords.csv'] = { mime_type: 'text/csv', content: @teacher_csv }
    make_bootstrap_mail(to: @user.email, subject: 'Tenjin User Passwords')
  end
end
