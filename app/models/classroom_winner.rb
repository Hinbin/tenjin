class ClassroomWinner < ApplicationRecord
  belongs_to :classroom
  belongs_to :user
  has_one :school, through: :classroom

  validate :user_and_classroom_schools_match

  private

  def user_and_classroom_schools_match
    return if classroom.school_id == user.school_id

    errors[:base] << 'Classroom school does not match user school'
  end
end
