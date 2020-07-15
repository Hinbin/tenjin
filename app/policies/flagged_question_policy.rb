# frozen_string_literal: true

class FlaggedQuestionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def create?
    true
  end
end
