class TopicScore < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  has_one :subject, through: :topic
end
