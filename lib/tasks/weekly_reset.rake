namespace :weekly_reset do
  desc 'Resetting weekly leaderboard'
  task leaderboard: :environment do
    today = Date.current
    Leaderboard::ResetWeeklyLeaderboard.call if today.monday?
  end
end
