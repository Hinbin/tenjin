# frozen_string_literal: true

class QuizPolicy < ApplicationPolicy
  def initialize(user, quiz)
    super
    @quiz = quiz
  end

  def show?
    @user.id == @quiz.user_id
  end

  def update?
    @user.id == @quiz.user_id && @quiz.active
  end

  def new?
    return false if @quiz.subject.nil?

    (@user.subjects.include? @quiz.subject) && @user.school.permitted?
  end

  def create?
    @user.id == @quiz.user_id && @quiz.active
  end

  class Scope < Scope
    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where('active = ? and user_id = ?', true, @user.id)
    end
  end
end
