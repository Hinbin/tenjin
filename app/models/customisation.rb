class Customisation < ApplicationRecord
  enum customisation_type: %i[dashboard_style leaderboard_icon]
end
