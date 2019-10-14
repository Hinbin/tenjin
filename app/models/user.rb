class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Note - removed :registerable so new accounts cannot be created
  devise :database_authenticatable, :rememberable, :trackable, :recoverable,
         :omniauthable, omniauth_providers: [:wonde], authentication_keys: [:login]

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

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  # Needed to allow users to sign in with either a username or an email
  attr_writer :login

  def login
    @login || username || email
  end

  def school_employee?
    school_admin? || employee?
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  def set_default_role
    self.role ||= :student
  end

  def self.from_omniauth(auth)
    where(provider: auth['provider'], upi: auth['upi']).first
  end

  def self.from_wonde(school, classroom, classroom_db)
    create_employee_users(classroom, school)

    return unless classroom_db.subject.present?

    create_student_users(classroom, school)
  end

  def seconds_left_on_cooldown
    return -1 if time_of_last_quiz.nil?

    (QUIZ_COOLDOWN_PERIOD - (Time.current - Time.parse(time_of_last_quiz.to_s))).round
  end

  class << self
    private

    def create_student_users(classroom, school)
      return unless classroom.subject.present?
      return unless classroom.students.present?
      return unless classroom.students.data.present?

      classroom.students.data.each do |student|
        u = initialize_user(student, 'student', school)
        u.save
      end
    end

    def create_employee_users(classroom, school)
      return unless classroom.subject.present?
      return unless classroom.employees.present?
      return unless classroom.employees.data.present?

      classroom.employees.data.each do |employee|
        u = initialize_user(employee, 'employee', school)
        u.save
      end
    end

    def generate_username(u)
      u.username = u.forename[0].downcase + u.surname.downcase + u.upi[0..3]
      u.username = u.username + '1' while User.where(username: u.username).count.positive?
    end

    def initialize_user(user, role, school)
      u = User.where(provider: 'Wonde', upi: user.upi).first_or_initialize
      u.school_id = school.id
      u.role = role unless u.role == 'school_admin'
      u.provider = 'Wonde'
      u.upi = user.upi
      u.forename = user.forename
      u.surname = user.surname
      u.challenge_points = 0 if user.challenge_points.blank?
      u.disabled = false
      generate_username(u) if u.new_record? || u.username.blank?
      u
    end
  end
end
