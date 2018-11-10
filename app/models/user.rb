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
    where(provider: auth['provider'], upi: auth['upi']).first_or_create do |user|
      user.provider = auth['provider']
      user.upi = auth['upi']
      user.forename = auth['forename']
      user.surname = auth['surname']
      user.role = auth['type']
      user.school_id = auth['School']['id']
    end
  end
end
