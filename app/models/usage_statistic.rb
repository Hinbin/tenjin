# frozen_string_literal: true

class UsageStatistic < ApplicationRecord
  belongs_to :user
  belongs_to :topic, optional: true
  belongs_to :lesson, optional: true
end
