class QuizPolicy < ApplicationPolicy
  def initialize(user, quiz)
    @user = user
    @quiz = quiz
  end

  def show?
    @user.id == @quiz.user_id && @quiz.active
  end

  def update?
    @user.id == @quiz.user_id && @quiz.active
  end

  def new?
    return false if @quiz.subject.nil?

    @user.school.permitted? && @user.subjects.exists?(@quiz.subject.id)
  end

  def create?
    @user.id == @quiz.user_id && @quiz.active
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where('active = ? and user_id = ?', true, @user.id)
    end
  end
end
