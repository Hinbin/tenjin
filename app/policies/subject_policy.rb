# frozen_string_literal: true

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.with_role(:question_author, user)
    end
  end

  def update?
    user.has_role? :question_author, record
  end

  alias create? update?
  alias destroy? update?
end
