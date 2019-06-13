class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :model, :record

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(school: @user.school)
    end
  end

  def initialize(current_user, model)
    @current_user = current_user
    @user = model
  end

  def index?
    @current_user.school_admin?
  end

  def show?
    return @current_user.school == @user.school if @current_user.employee?

    @current_user == @user && @user.school.permitted
  end

  def update?
    @current_user.school_employee? && @user.school == @current_user.school
  end

  def destroy?
    return false if @current_user == @user

    @current_user.admin_school?
  end
end
