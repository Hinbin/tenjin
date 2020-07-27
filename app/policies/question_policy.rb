# frozen_string_literal: true

class QuestionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Subject.with_role(:question_author, user).where(active: true)
    end
  end

  def update?
    user.has_role? :question_author, record.topic.subject
  end

  alias create? update?
  alias destroy? update?
  alias show? update?
end
