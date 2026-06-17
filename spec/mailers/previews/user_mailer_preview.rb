# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def setup_email
    user = User.first
    UserMailer.with(user: user).setup_email
  end
end
