# frozen_string_literal: true

class HomeworkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.school_admin?
        scope.joins(:classroom).where(classrooms: { school: user.school })
      else
        scope.where(classroom_id: user.classrooms)
      end
    end
  end

  def new?
    @user.school_employee? && @record.classroom.school == @user.school
  end

  def create?
    @user.school_employee? && @record.classroom.school == @user.school
  end

  def destroy?
    @user.school_employee? && @record.classroom.school == @user.school
  end

  def show?
    @record.classroom.school == @user.school
  end
end
