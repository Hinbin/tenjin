# frozen_string_literal: true

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def update?
    user.super?
  end

  def flagged_questions?
    user.has_role? :question_author, record
  end

  alias create? update?
  alias destroy? update?
  alias show? update?
  alias new? update?
end
