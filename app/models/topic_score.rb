class TopicScore < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  has_one :subject, through: :topic

  validates :score, numericality: { greater_than_or_equal_to: 0 }
end
