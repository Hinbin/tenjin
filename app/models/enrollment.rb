class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :classroom

  has_one :subject, through: :classroom

  validates :user, uniqueness: { scope: [:classroom] }

  def self.from_wonde(classroom_api_data)
    classroom = Classroom.find_by(client_id: classroom_api_data.id)

    return unless classroom.subject_id.present?

    enroll_users_to_classroom(classroom_api_data, classroom)
  end

  class << self
    private

    def enroll_users_to_classroom(classroom_api_data, classroom)
      # To handle updates to classrooms, delete all existing enrollments and start again
      classroom.enrollments.destroy_all
      create_classroom_enrollments(classroom_api_data.students, classroom) if classroom_api_data.students.present?
      create_classroom_enrollments(classroom_api_data.employees, classroom) if classroom_api_data.employees.present?
    end

    def create_classroom_enrollments(students_data, classroom)
      return unless students_data.data.present?

      students = students_data.data
      students.each do |s|
        student = User.find_by(upi: s.upi)
        create_enrollment(classroom, student)
      end

      classroom.update_attribute('disabled', classroom.enrollments.count.zero? ? true : false)
    end

    def destroy_classroom_enrollments(classroom)
      Enrollment.where(classroom: classroom).destroy_all
    end

    def create_enrollment(classroom, student)
      e = Enrollment.where(classroom: classroom, user: student).first_or_initialize
      e.user = student
      e.classroom = classroom
      e.save
    end
  end
end
