# frozen_string_literal: true

class LessonPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(subject: user.subjects)
    end
  end
end
