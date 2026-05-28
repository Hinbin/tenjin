# frozen_string_literal: true

class SchoolGroupPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user.super? || user.school_group?

      scope.all
    end
  end

  def new?
    user.super?
  end

  def create?
    user.super?
  end

  def update?
    user.super?
  end

  def destroy?
    user.super?
  end
end
