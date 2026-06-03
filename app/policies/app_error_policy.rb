# frozen_string_literal: true

class AppErrorPolicy < ApplicationPolicy
  def index?
    user.super?
  end

  def show?
    user.super?
  end

  class Scope < Scope
    def resolve
      user.super? ? scope.all : scope.none
    end
  end
end
