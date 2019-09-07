class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :classroom

  has_one :subject, through: :classroom

  validates :user, uniqueness: { scope: [:classroom] }

  def self.from_wonde(school, classroom_api_data)
    mapped_subjects = SubjectMap.subject_maps_for_school(school)

    subject = mapped_subjects.where(client_subject_name: classroom_api_data.subject.data.name).first
    return unless subject.present?

    classroom = Classroom.classroom_from_client_id(classroom_api_data.id)

    update_classrooms(classroom_api_data, classroom)
  end

  class << self
    private

    def update_classrooms(classroom_api_data, classroom)
      # To handle updates to classrooms, delete all existing enrollments and start again
      classroom.enrollments.destroy_all
      create_classroom_enrollments(classroom_api_data.students, classroom) if classroom_api_data.students.present?
      create_classroom_enrollments(classroom_api_data.employees, classroom) if classroom_api_data.employees.present?
    end

    def create_classroom_enrollments(students_data, classroom)
      return unless students_data.data.present?

      students = students_data.data
      students.each do |s|
        student = User.user_from_upi(s.upi)
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
