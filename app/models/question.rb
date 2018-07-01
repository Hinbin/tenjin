class Question < ApplicationRecord
  has_many :answers
  has_many :asked_questions
  has_many :quizzes, through: :asked_questions
end
