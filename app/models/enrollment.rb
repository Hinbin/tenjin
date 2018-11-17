class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :classroom

  def self.from_wonde(school, sync_data)
    mapped_subjects = SubjectMap.subjects_for_school(school)

    sync_data.each do |c|
      subject = mapped_subjects.where(client_subject_name: c.subject.data.name).first
      next unless subject.present?

      classroom = Classroom.classroom_from_client_id(c.id)

      # To handle updates to classrooms, delete all existing enrollments and start again
      destroy_classroom_enrollments(classroom)
      create_classroom_enrollments(c.students.data, classroom)
      create_classroom_enrollments(c.employees.data, classroom)
    end
  end

  def self.create_classroom_enrollments(students, classroom)
    students.each do |s|
      student = User.user_from_upi(s.upi)
      create_enrollment(classroom, student)
    end
  end

  def self.destroy_classroom_enrollments(classroom)
    Enrollment.where(classroom: classroom).destroy_all
  end

  def self.create_enrollment(classroom, student)
    e = Enrollment.where(classroom: classroom, user: student).first_or_initialize
    e.user = student
    e.classroom = classroom
    e.save
  end
end
