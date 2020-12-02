# frozen_string_literal: true

class CustomisationPolicy < ApplicationPolicy
  def index?
    user.super?
  end

  alias show? index?
  alias edit? index?
  alias update? index?
  alias new? index?
  alias create? index?

  class Scope < Scope
    def resolve
      return scope.all if user.super?
    end
  end
end
