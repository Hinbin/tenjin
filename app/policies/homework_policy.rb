class HomeworkPolicy < ApplicationPolicy
  
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
