# frozen_string_literal: true

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def update?
    user.super?
  end

  alias create? update?
  alias destroy? update?
  alias show? update?
end
