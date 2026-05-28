# frozen_string_literal: true

class QuestionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(topic: :subject)
        .where(topics: {active: true}, subjects: {active: true, id: Subject.with_role(:question_author, user).select(:id)})
    end
  end

  def update?
    user.has_role? :question_author, record.topic.subject
  end

  alias_method :create?, :update?
  alias_method :destroy?, :update?
  alias_method :show?, :update?
end
