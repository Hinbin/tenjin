# frozen_string_literal: true

module System
  class ApplicationPolicy
    attr_reader :admin, :record
    alias_method :user, :admin

    def initialize(admin, record)
      @admin = admin
      @record = record
    end

    def index? = false
    def show? = false
    def create? = false
    def new? = create?
    def update? = false
    def edit? = update?
    def destroy? = false

    private

    def super? = admin.super?
    def school_group? = admin.school_group?

    class Scope
      def initialize(admin, scope)
        @admin = admin
        @scope = scope
      end

      def resolve
        raise NoMethodError, "#{self.class} must implement #resolve"
      end

      private

      attr_reader :admin, :scope
      alias_method :user, :admin

      def super? = admin.super?
      def school_group? = admin.school_group?
    end
  end
end
