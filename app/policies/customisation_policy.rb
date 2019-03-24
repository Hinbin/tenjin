class CustomisationPolicy < ApplicationPolicy
  def initialize(user, customisation)
    @user = user
    @customisation = customisation
  end

  def show?
    true
  end

  def update?
    true
  end
  
end