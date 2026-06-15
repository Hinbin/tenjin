# frozen_string_literal: true

module System
  class AdminPolicy < System::ApplicationPolicy
    def show? = super?
    def new? = super?
    def manage_roles? = super?
    def reset_year? = super?
    def show_stats? = super? || school_group?
  end
end
