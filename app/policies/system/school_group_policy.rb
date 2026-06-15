# frozen_string_literal: true

module System
  class SchoolGroupPolicy < System::ApplicationPolicy
    def new? = super?
    def create? = super?
    def update? = super?
    def destroy? = super?

    class Scope < Scope
      def resolve
        return scope.none unless super? || school_group?

        scope.all
      end
    end
  end
end
