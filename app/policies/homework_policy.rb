class HomeworkPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      if user.school_admin?
        scope.all
      else
        scope.where(classroom_id: user.classrooms)
      end
    end
  end

  def new?
    @user.employee?
  end

  def create?
    @user.employee?
  end

  def destroy?
    @user.employee?
  end

  def show?
    @user.school.permitted?
  end
end
