# frozen_string_literal: true

class Multiplier < ApplicationRecord
  validates :score, presence: true, uniqueness: true
  validates :multiplier, presence: true
end
