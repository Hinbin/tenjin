class AdminPolicy < ApplicationPolicy
  def become?
    record.super?
  end
end
