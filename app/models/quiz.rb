# frozen_string_literal: true

class Quiz < ApplicationRecord
  LUCKY_DIP = "Lucky Dip"

  belongs_to :user
  belongs_to :subject
  belongs_to :topic, optional: true
  belongs_to :lesson, optional: true

  has_many :asked_questions
  has_many :questions, through: :asked_questions
  attr_accessor :picked_subject

  after_create :update_usage_statistics

  private

  def update_usage_statistics
    s = UsageStatistic.where(user: user, topic: topic, lesson: lesson, date: Date.current).first_or_create!
    s.increment!(:quizzes_started)
  end
end
