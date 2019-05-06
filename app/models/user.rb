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
  has_many :topic_scores
  has_many :homeworks, through: :classrooms

  belongs_to :school

  enum role: %i[student employee contact school_admin]
  validates :upi, presence: true
  validates :role, presence: true

  QUIZ_COOLDOWN_PERIOD = 40

  # Disable the requirements for a password and e-mail as we're getting our
  # users from Wonde, which will provide neither.

  def set_default_role
    self.role ||= :student
  end

  def self.user_from_upi(upi)
    User.where(upi: upi).first
  end

  def self.from_omniauth(auth)
    where(provider: auth['provider'], upi: auth['upi']).first
  end

  def self.from_wonde(school, sync_data)
    mapped_subjects = SubjectMap.subject_maps_for_school(school)
    # We only want entries for students that are completing subjects
    # covered by the quiz platform
    sync_data.each do |classroom|
      subject = mapped_subjects.where(client_subject_name: classroom.subject.data.name).first
      next unless subject.present?

      create_student_users(classroom, school)
      create_employee_users(classroom, school)
    end
  end

  def seconds_left_on_cooldown
    return -1 if time_of_last_quiz.nil?

    (QUIZ_COOLDOWN_PERIOD - (Time.now - Time.parse(time_of_last_quiz.to_s))).round
  end

  class << self
    private

    def create_student_users(classroom, school)
      return unless classroom.students.present?
      return unless classroom.students.data.present?

      classroom.students.data.each do |student|
        create_user(student, 'student', school)
      end
    end

    def create_employee_users(classroom, school)
      return unless classroom.employees.present?
      return unless classroom.employees.data.present?

      classroom.employees.data.each do |student|
        create_user(student, 'employee', school)
      end
    end

    def create_user(user, role, school)
      u = User.where(provider: 'Wonde', upi: user.upi).first_or_initialize
      u.school = school
      u.role = role
      u.provider = 'Wonde'
      u.upi = user.upi
      u.forename = user.forename
      u.surname = user.surname
      u.challenge_points = 0
      u.save
    end
  end
end
