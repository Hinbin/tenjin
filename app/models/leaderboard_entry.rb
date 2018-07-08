class LeaderboardEntry < ApplicationRecord
  belongs_to :user
  belongs_to :classroom
end
