# frozen_string_literal: true

require 'csv'

class ResetUserPasswordsJob < ApplicationJob
  queue_as :default

  def perform(user)
    @user = user

    @student_csv = reset_passwords(find_students)
    @teacher_csv = reset_passwords(find_teachers)

    UserPasswordsMailer.with(user: @user, student_csv: @student_csv, teacher_csv: @teacher_csv)
                       .user_passwords_email.deliver_later
  end

  private

  def find_students
    find_users.where(role: 'student')
  end

  def find_teachers
    find_users.where(role: 'employee')
  end

  def find_users
    User.includes(:classrooms)
        .where(school: @user.school)
        .where(disabled: false)
        .where.not(id: User.with_role(:school_admin))
        .where(sign_in_count: 0)
        .order('classrooms.name')
  end

  def reset_passwords(users)
    CSV.generate do |csv|
      csv << ['Username', 'First Name', 'Last Name', 'Classrooms', 'Password']
      users.each do |u|
        new_password = Devise.friendly_token.first(6)
        if u.reset_password(new_password, new_password)
          csv << [u.username, u.forename, u.surname, u.classrooms.pluck(:name).join(' '), new_password]
        end
      end
    end
  end
end
