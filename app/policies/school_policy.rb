# frozen_string_literal: true

class SchoolPolicy < ApplicationPolicy
  def reset_all_passwords?
    user.has_role?(:school_admin) && user.school == record
  end

  def sync?
    user.has_role?(:school_admin) && user.school == record
  end
end
