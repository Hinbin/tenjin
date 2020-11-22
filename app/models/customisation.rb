# frozen_string_literal: true

class Customisation < ApplicationRecord
  validates :cost, presence: true
  enum customisation_type: %i[dashboard_style leaderboard_icon subject_image]

  has_many :customisation_unlocks
  has_many :active_customisations

  has_one_attached :image
end
