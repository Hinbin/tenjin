# frozen_string_literal: true

class Multiplier < ApplicationRecord
  validates :score, presence: true, uniqueness: true
  validates :multiplier, presence: true

  def self.for_streak(streak)
    where(score: ..streak).order(score: :desc).pick(:multiplier)
  end
end
