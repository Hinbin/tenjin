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

  def create?
    user.has_role? :lesson_author, record.subject
  end
end
