# frozen_string_literal: true

class LessonPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.includes(:topic)
        .where(topics: {subject_id: user.subjects})
    end
  end

  def new?
    user.has_role? :lesson_author, record.subject
  end

  def view_questions?
    return false if user.student?

    user.subjects.include?(record.subject) || user.has_role?(:question_author, :any)
  end

  alias_method :create?, :new?
  alias_method :edit?, :new?
  alias_method :update?, :new?
  alias_method :destroy?, :new?
end
