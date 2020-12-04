# frozen_string_literal: true

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

  def new?
    user.super?
  end

  def reset_all_passwords?
    user.has_role?(:school_admin) && user.school == record
  end

  def show?
    user.super? || user.school_group?
  end

  def create?
    user.super?
  end

  def update?
    user.super?
  end

  def sync?
    return true if user.class == Admin && user.super?
    return true if user.class == User && user.has_role?(:school_admin) && user.school == record

    false
  end

  def destroy?
    user.super?
  end
end
