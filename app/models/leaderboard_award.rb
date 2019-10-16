# frozen_string_literal: true

class LeaderboardAward < ApplicationRecord
  belongs_to :school
  belongs_to :user
  belongs_to :subject
end
