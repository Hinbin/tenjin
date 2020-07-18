# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Note - removed :registerable so new accounts cannot be created
  devise :database_authenticatable, :rememberable, :trackable, :recoverable,
         :omniauthable, omniauth_providers: %i[wonde google_oauth2], authentication_keys: [:login]

  has_many :quizzes
  has_many :enrollments
  has_many :classrooms, through: :enrollments
  has_many :subjects, through: :classrooms
  has_many :topic_scores
  has_many :homeworks, through: :classrooms

  belongs_to :school

  enum role: { student: 0, employee: 1, contact: 2, school_admin: 3 }
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

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value',
                                    { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  def set_default_role
    self.role ||= :student
  end

  def self.from_omniauth(auth, current_user = nil)
    user = find_by(provider: auth['provider'], upi: auth['upi'])
    user = find_by(oauth_provider: auth['provider'], oauth_uid: auth['uid']) if user.nil?

    return user if user.present?

    # If signed in and its an oauth2 google request, assume linking of accounts
    return unless auth['provider'] == 'google_oauth2' && current_user.present?

    save_oauth_user_details(auth, current_user)
  end

  def self.save_oauth_user_details(auth, current_user)
    return unless auth['info'].present?

    current_user.oauth_uid = auth['uid']
    current_user.oauth_provider = auth['provider']
    current_user.oauth_email = auth['info']['email']
    current_user.save
    current_user
  end

  def self.unlink_account
    current_user.oauth_uid = ''
    current_user.oauth_provider = ''
    current_user.save
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

    def generate_username(user)
      user.forename.strip[0].downcase.tap do |str|
        add_surname_letters(user, str)
      end
    end

    def add_surname_letters(user, str)
      str << user.surname.strip.downcase << user.upi[0..3]
      str.next! while User.where(username: str).exists?
    end

    def initialize_user(user, role, school)
      u = User.where(provider: 'Wonde', upi: user.upi).first_or_initialize
      u.attributes = { school_id: school.id, role: role, provider: 'Wonde',
                       upi: user.upi, forename: user.forename, surname: user.surname, disabled: false }
      u.challenge_points = 0 if u.challenge_points.blank?
      u.username = generate_username(u) if u.new_record? || u.username.blank?
      u
    end
  end
end
