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
    @user.employee? || @user.school_admin?
  end

  def create?
    @user.employee? || @user.school_admin?
  end

  def destroy?
    @user.employee? || @user.school_admin?
  end

  def show?
    @user.school.permitted? && @record.classroom.school == @user.school
  end
end
