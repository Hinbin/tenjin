# frozen_string_literal: true

class TopicPolicy < ApplicationPolicy
  # Also used to authorize editing questions for a topic

  class Scope < Scope
    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(active: true,
                   subject_id: Subject.with_role(:question_author, user)
                                      .where(active: true)
                                      .pluck(:id))
    end
  end

  def update?
    user.has_role? :question_author, record.subject
  end

  alias create? update?
  alias destroy? update?
  alias show? update?
end
