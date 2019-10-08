# Resets the passwords for a group of users, and returns their new passwords
class User::ResetUserPasswords < ApplicationService
  def initialize(user, school = nil)
    @user = user
    @school = school
    @user_data = {}
    @users = []
  end

  def call
    return OpenStruct.new(success?: false, user: @user, errors: 'User not found') unless @user.present?

    find_users
    return OpenStruct.new(success?: false, user: @user, errors: 'No users found for school') unless @users.present?

    reset_user_list_passwords

    OpenStruct.new(success?: true, user_data: @user_data)
  end

  private

  def find_users
    @users = UserPolicy::Scope.new(@user, User).resolve.where(role: %w[student employee])
                              .where(disabled: false)
                              .includes(:school)
  end

  def reset_user_list_passwords
    @users.each do |u|
      new_password = Devise.friendly_token.first(6)
      @user_data[u.upi] = new_password if u.reset_password(new_password, new_password)
    end
  end
end
