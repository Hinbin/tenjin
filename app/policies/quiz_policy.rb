# frozen_string_literal: true

class QuizPolicy < ApplicationPolicy
  def show?
    user.id == record.user_id
  end

  def update?
    user.id == record.user_id && record.active
  end

  def new?
    return false if record.subject.nil?

    user.subjects.include?(record.subject) && user.school.permitted?
  end

  alias_method :create?, :update?

  class Scope < Scope
    def resolve
      scope.where(active: true, user_id: user.id)
    end
  end
end
