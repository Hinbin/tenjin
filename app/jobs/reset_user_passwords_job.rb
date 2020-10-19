# frozen_string_literal: true
require 'csv'

class ResetUserPasswordsJob < ApplicationJob
  queue_as :default

  def perform(user, school)
    @user = user
    @school = school

    find_users
    @csv = reset_passwords

    UserPasswordsMailer.with(user: @user, csv: @csv).user_passwords_email.deliver_later
  end

  private

  def find_users
    @users = UserPolicy::Scope.new(@user, User).resolve.where(role: %w[student employee])
                              .where(disabled: false)
                              .where.not(id: User.with_role(:school_admin))
                              .where(sign_in_count: 0)
                              .includes(:school)
  end

  def reset_passwords
    CSV.generate do |csv|
      @users.each do |u|
        new_password = Devise.friendly_token.first(6)
        if u.reset_password(new_password, new_password)
          csv << [u.username, u.forename, u.surname, u.classrooms.pluck(:name).join(' '), new_password]
        end
      end
    end
  end
end

