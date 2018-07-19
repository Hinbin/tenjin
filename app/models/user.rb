class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Note - removed :registerable so new accounts cannot be created
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  has_many :quizzes
  has_many :enrollments
  has_many :classrooms, through: :enrollments
  has_many :subjects, through: :classrooms
  belongs_to :school

  enum role: %i[student teacher school_admin mat_admin admin]
  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :student
  end

  def self.from_omniauth(auth)
    existing_user = where(email: auth.info.email).first

    unless existing_user.blank?
      existing_user.provider = auth.provider
      existing_user.uid = auth.uid
      existing_user.password = Devise.friendly_token[0, 20]
      existing_user.name = auth.info.name   # assuming the user model has a name
      existing_user.image = auth.info.image # assuming the user model has an image
      existing_user.save
    end

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name   # assuming the user model has a name
      user.image = auth.info.image # assuming the user model has an image

      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end
end
