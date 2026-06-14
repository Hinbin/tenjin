# frozen_string_literal: true

module System
  class SubjectPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.all
      end
    end

    def update?
      user.super?
    end

    alias_method :create?, :update?
    alias_method :destroy?, :update?
    alias_method :show?, :update?
    alias_method :new?, :update?
  end
end
