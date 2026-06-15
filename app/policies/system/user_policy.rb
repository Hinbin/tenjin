# frozen_string_literal: true

module System
  class UserPolicy < System::ApplicationPolicy
    def become? = super? || school_group?

    def set_role? = super? && record.employee?

    alias_method :remove_role?, :set_role?
    alias_method :update_email?, :set_role?
    alias_method :send_welcome_email?, :set_role?

    class Scope < Scope
      def resolve = scope.all
    end
  end
end
