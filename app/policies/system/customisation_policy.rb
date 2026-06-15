# frozen_string_literal: true

module System
  class CustomisationPolicy < System::ApplicationPolicy
    def index? = super?

    alias_method :show?, :index?
    alias_method :edit?, :index?
    alias_method :update?, :index?
    alias_method :new?, :index?
    alias_method :create?, :index?

    class Scope < Scope
      def resolve
        scope.all if super?
      end
    end
  end
end
