# frozen_string_literal: true

module System
  class SchoolPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.all
      end
    end

    def new?
      user.super?
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

    def destroy?
      user.super?
    end

    def sync?
      user.super?
    end
  end
end
