class SchoolPolicy < ApplicationPolicy
  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.all
    end
  end

  def initialize(user, permitted_school)
    @user = user
    @permitted_school = permitted_school
  end

  def new?
    @user.super?
  end

  def show?
    @user.super?
  end

  def create?
    @user.super?
  end

  def update?
    @user.super?
  end

  def destroy?
    @user.super?
  end
end
