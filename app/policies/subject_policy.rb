# frozen_string_literal: true

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.all
    end
  end

  def update?
    must_be_super_or_author
  end

  def create?
    must_be_super_or_author
  end

  def destroy?
    must_be_super_or_author
  end

  def must_be_super_or_author
    return false unless @user.present?

    @user.author? || @user.super?
  end
end
