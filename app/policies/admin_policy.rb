# frozen_string_literal: true

class AdminPolicy < ApplicationPolicy
  def manage_roles?
    user.super?
  end

  def show_stats?
    user.super?
  end

  def reset_year?
    user.super?
  end

  def show?
    user.super?
  end
end
