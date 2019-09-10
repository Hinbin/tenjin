# Resets the passwords for a group of users, and returns their new passwords
class User::ResetUserPasswords
  def initialize(admin, school = nil)
    @admin = admin
    @school = school
    @user_data = {}
    @users = []
  end

  def call
    return OpenStruct.new(success?: false, admin: @admin, errors: 'User not found') unless @admin.present?

    find_users
    return OpenStruct.new(success?: false, admin: @admin, errors: 'No users found for school') unless @users.present?

    reset_user_list_passwords

    OpenStruct.new(success?: true, user_data: @user_data)
  end

  private

  def find_users
    @users = UserPolicy::Scope.new(@admin, User).resolve.where(role: 'student').includes(:school) if @admin.class.name == 'User'
    @users = User.where(school: @school).includes(:school) if @admin.class.name == 'Admin'
  end

  def reset_user_list_passwords
    Devise.stretches = 1
    @users.each do |u|
      new_password = Devise.friendly_token.first(6)
      @user_data[u.upi] = new_password if u.reset_password(new_password, new_password)
    end
    Devise.stretches = 10
  end
end
