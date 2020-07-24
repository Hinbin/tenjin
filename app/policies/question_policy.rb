# frozen_string_literal: true

class QuestionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      #scope.joins(topic: :subject).where(active: true, topics: { subject: Subject.with_role(:question_author, user).pluck(:id) })
      Subject.with_role(:question_author, user)
    end
  end

  def update?
    user.has_role? :question_author, record.topic.subject
  end

  alias create? update?
  alias destroy? update?
  alias show? update?
end
