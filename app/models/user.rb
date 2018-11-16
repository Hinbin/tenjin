class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Note - removed :registerable so new accounts cannot be created
  devise :rememberable, :trackable,
         :omniauthable, omniauth_providers: [:wonde]

  has_many :quizzes
  has_many :enrollments
  has_many :classrooms, through: :enrollments
  has_many :subjects, through: :classrooms
  belongs_to :school

  enum role: %i[student employee contact admin_school admin_mat admin]

  # Disable the requirements for a password and e-mail as we're getting our
  # users from Wonde, which will provide neither.

  def set_default_role
    self.role ||= :student
  end

  def self.from_omniauth(auth)
    where(provider: auth['provider'], upi: auth['upi']).first
  end

  def self.from_wonde(school, sync_data)
    mapped_subjects = SubjectMap.subjects_for_school(school)

    # We only want entries for students that are completing subjects
    # covered by the quiz platform

    sync_data.each do |classroom|
      subject = mapped_subjects.where(client_subject_name: classroom.subject.data.name).first
      next unless subject.present?

      classroom.students.data.each do |student|
        create_student(student, school)
      end
    end
  end

  def self.create_student(student, school)
    u = User.where(provider: 'Wonde', upi: student.upi).first_or_initialize
    u.school = school
    u.role = 'student'
    u.provider = 'Wonde'
    u.upi = student.upi
    u.forename = student.forename
    u.surname = student.surname
    u.save
  end

  def self.user_from_upi(upi)
    User.where(upi: upi).first
  end
end
