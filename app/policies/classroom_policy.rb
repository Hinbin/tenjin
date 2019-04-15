class ClassroomPolicy < ApplicationPolicy
  def show?
    user.role == 'employee'
  end
end