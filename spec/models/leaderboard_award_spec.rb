# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeaderboardAward do
  it "has a valid factory" do
    expect(build(:leaderboard_award)).to be_valid
  end

  it "is invalid without required associations" do
    expect(build(:leaderboard_award, :without_user)).not_to be_valid
  end
end
