class Lesson < ApplicationRecord
  enum type: %i[video]
  has_many :questions
end
