# frozen_string_literal: true

class ClassroomPolicy < ApplicationPolicy
  def show?
    user.employee?
  end

  # Gap analysis exposes per-student performance, so it is scoped to the teacher's own school —
  # tighter than #show. The student-drill action additionally loads the pupil through the
  # classroom's enrolments, so a teacher cannot reach a pupil outside the class.
  def gaps?
    user.employee? && @record.school == user.school
  end

  def update?
    user.has_role?(:school_admin) && @record.school == user.school
  end

  class Scope < Scope
    def resolve
      scope.where(school: user.school)
    end
  end
end
