# frozen_string_literal: true

class TopicScore < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  has_one :subject, through: :topic
  has_one :school, through: :user

  validates :score, numericality: { greater_than_or_equal_to: 0 }
  validates :user, uniqueness: { scope: [:topic] }
end
