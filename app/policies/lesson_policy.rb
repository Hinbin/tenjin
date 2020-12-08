# frozen_string_literal: true

class LessonPolicy < ApplicationPolicy
  attr_reader :user, :record

  class Scope < Scope
    def resolve
      scope.includes(:topic)
           .where(topics: { subject_id: user.subjects })
    end
  end

  def new?
    user.has_role? :lesson_author, record.subject
  end

  def view_questions?
    return false if user.student?

    user.subjects.include?(record.subject) || user.has_role?(:question_author, :any)
  end

  alias create? new?
  alias edit? new?
  alias update? new?
  alias destroy? new?
end
