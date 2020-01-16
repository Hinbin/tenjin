# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def setup_email
    new_password = Devise.friendly_token(6)
    @user = User.first

    UserMailer.with(user: @user, password: new_password).setup_email
  end
end
