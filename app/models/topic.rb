# frozen_string_literal: true

class Topic < ApplicationRecord
  belongs_to :subject
  has_many :questions, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :topic_scores, dependent: :destroy
  has_many :all_time_topic_scores, dependent: :destroy
  has_many :challenges, dependent: :destroy
  has_many :homeworks, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :usage_statistics, dependent: :destroy

  belongs_to :default_lesson,
             optional: true,
             class_name: 'Lesson'

  validates :name, presence: true

  before_destroy { |record| UsageStatistic.where(topic: record).update_all(topic_id: nil) }
end
