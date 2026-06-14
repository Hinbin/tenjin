# frozen_string_literal: true

module System
  class UserPolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        scope.all
      end
    end

    def become?
      user.super? || user.school_group?
    end

    def set_role?
      user.super? && record.employee?
    end

    alias_method :remove_role?, :set_role?
    alias_method :update_email?, :set_role?
    alias_method :send_welcome_email?, :set_role?
  end
end
