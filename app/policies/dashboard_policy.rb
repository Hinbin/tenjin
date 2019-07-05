class DashboardPolicy < ApplicationPolicy
  attr_reader :current_user, :model, :record

  def show?
    record == @user
  end

end
