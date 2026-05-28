# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  attr_reader :current_user, :model, :record

  def show?
    user == record
  end
end
