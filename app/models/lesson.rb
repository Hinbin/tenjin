class Lesson < ApplicationRecord
  enum type: %i[video]
  has_many :questions
  has_many :subjects, through: :questions
end
