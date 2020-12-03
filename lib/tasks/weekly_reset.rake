# frozen_string_literal: true

namespace :weekly_reset do
  desc 'Resetting weekly leaderboard'
  task leaderboard: :environment do
    today = Date.current
    if today.monday?
      Leaderboard::ResetWeeklyLeaderboard.call
      Customisation::RefreshCustomisationsInStore.call
    end
  end
end
