# frozen_string_literal: true

module System
  class CustomisationPolicy < ApplicationPolicy
    def index?
      user.super?
    end

    alias_method :show?, :index?
    alias_method :edit?, :index?
    alias_method :update?, :index?
    alias_method :new?, :index?
    alias_method :create?, :index?

    class Scope < Scope
      def resolve
        scope.all if user.super?
      end
    end
  end
end
