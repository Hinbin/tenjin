class Customisation < ApplicationRecord
  validates :cost, presence: true
  enum customisation_type: %i[dashboard_style leaderboard_icon subject_image]
end
