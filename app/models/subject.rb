# frozen_string_literal: true

class Subject < ApplicationRecord
  resourcify

  has_many :topics
  has_many :classrooms
  has_many :lessons

  validates :name, presence: true, uniqueness: true

  def flagged_questions
    Question.joins(:topic)
            .includes(:question_statistic, :lesson, :rich_text_question_text)
            .where(topics: { subject: id })
            .where(flagged_questions_count: 1..)
            .where(active: true)
            .order(flagged_questions_count: :desc)
            .limit(20)
  end
end
