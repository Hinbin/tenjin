# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :user
  belongs_to :subject
  belongs_to :topic, optional: true

  has_many :asked_questions
  has_many :questions, through: :asked_questions
  attr_accessor :topic_id, :picked_subject

  after_create :update_usage_statistics

  private

  def update_usage_statistics
    s = UsageStatistic.where(user: user, topic: topic, date: Date.today).first_or_create!
    s.quizzes_started.present? ? s.increment!(:quizzes_started) : s.update_attribute(:quizzes_started, 1)
  end
end
