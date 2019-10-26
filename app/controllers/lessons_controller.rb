class LessonsController < ApplicationController
  def index
    @lessons = policy_scope(Lesson)

    return unless current_user.has_role? :lesson_author, :any

    @editable_subjects = Subject.with_role(:lesson_author, current_user)
    @editable_lessons = Lesson.where(subject: @editable_lessons)
  end
end