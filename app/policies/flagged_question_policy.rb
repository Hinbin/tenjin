# frozen_string_literal: true

class FlaggedQuestionPolicy < ApplicationPolicy
  def create?
    true
  end
end
