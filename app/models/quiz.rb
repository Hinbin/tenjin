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
    UsageStatistic.where(user: user, topic: topic, date: Date.today.all_day).first_or_create! do |s|
      if s.new_record?
        s.quizzes_started = 1
        s.user = user
        s.topic = topic
      else
        s.quizzes_started += 1
      end
      s.save!
    end
  end
end
