# frozen_string_literal: true

class UserPasswordsMailerPreview < ActionMailer::Preview
  def user_passwords_email
    user = User.first
    UserPasswordsMailer.with(
      user: user,
      student_csv: "login,password\nstudent1,abc123\n",
      teacher_csv: "login,password\nteacher1,xyz789\n"
    ).user_passwords_email
  end
end
