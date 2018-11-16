class UserSettingPolicy < ApplicationPolicy
  class SettingsPolicy < ApplicationPolicy
    def initialize(user, _quiz)
      @user = user
      @settings = settings
    end

    def show?
      @current_user.admin_school? || (@current_user == @user)
    end

    def update?
      @current_user.admin_school? || (@current_user == @user)
    end

    def destroy?
      return false if @current_user == @user

      @current_user.admin_school?
    end

    class Scope < Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @scope.where('user_id = ?', @user.id).first
      end
    end
  end
end
