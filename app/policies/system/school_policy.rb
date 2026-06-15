# frozen_string_literal: true

module System
  class SchoolPolicy < System::ApplicationPolicy
    def show? = super? || school_group?
    def new? = super?
    def create? = super?
    def update? = super?
    def destroy? = super?
    def sync? = super?

    class Scope < Scope
      def resolve = scope.all
    end
  end
end
