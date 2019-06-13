class ClassroomPolicy < ApplicationPolicy
  def show?
    user.employee? || user.school_admin?
  end
end
