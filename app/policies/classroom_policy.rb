class ClassroomPolicy < ApplicationPolicy
  def show?
    user.employee?
  end
end
