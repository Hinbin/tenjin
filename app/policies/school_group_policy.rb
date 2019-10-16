# frozen_string_literal: true

class SchoolGroupPolicy < ApplicationPolicy
  attr_reader :user, :record

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return false unless user.super?

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
