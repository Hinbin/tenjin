# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  class Scope < Scope
    def resolve
      scope.where(school: user.school, disabled: false)
    end
  end

  def index?
    user.has_role?(:school_admin)
  end

  def show?
    if user.has_role?(:school_admin)
      user.school == record.school
    elsif user.employee?
      (user.school == record.school) && (record.student? || user == record)
    else
      user == record
    end
  end

  def update?
    (user.employee? && record.school == user.school) || (record == user)
  end

  def destroy?
    return false if user == record

    user.has_role?(:school_admin)
  end

  def become?
    user.super?
  end

  def set_role?
    user.super? && record.employee?
  end

  alias remove_role? set_role?

  alias reset_password? show?
  alias unlink_oauth_account? show?

end
