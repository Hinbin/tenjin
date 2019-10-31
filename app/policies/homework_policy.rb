# frozen_string_literal: true

class HomeworkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.has_role?(:school_admin)
        scope.joins(:classroom).where(classrooms: { school: user.school })
      else
        scope.where(classroom_id: user.classrooms)
      end
    end
  end

  def new?
    @user.employee? && @record.classroom.school == @user.school
  end

  def create?
    @user.employee? && @record.classroom.school == @user.school
  end

  def destroy?
    @user.employee? && @record.classroom.school == @user.school
  end

  def show?
    @record.classroom.school == @user.school
  end
end
