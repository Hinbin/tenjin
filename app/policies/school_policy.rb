class SchoolPolicy < ApplicationPolicy
  attr_reader :user, :record

  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.all
    end
  end

  def new?
    user.super?
  end

  def reset_all_passwords?
    user.school_admin? && user.school == record
  end

  def show?
    user.super?
  end

  def create?
    user.super?
  end

  def update?
    user.super?
  end
  
  def sync?
    user.school_admin? && user.school == record
  end

  def destroy?
    user.super?
  end

  def show_employees?
    user.super?
  end
end
