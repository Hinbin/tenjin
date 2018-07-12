class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :quizzes
  has_many :enrollments
  has_many :classrooms, through: :leaderboard_entries
  has_many :subjects, through: :classrooms
  belongs_to :school
end
